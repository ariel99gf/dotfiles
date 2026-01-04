#!/bin/bash
set -e

# Cores para logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Diretório onde as chaves de desbloqueio automático ficarão (protegido pelo root criptografado)
KEY_DIR="/root/crypt_keys"

# Definição dos Discos (Label do Filesystem -> Nome do Mapper -> Ponto de Montagem -> Tipo FS)
# Formato: "LABEL_DISCO_FISICO|NOME_MAPPER|PONTO_MONTAGEM|TIPO_FS"
# NOTA: O Label aqui é do PARTITION ou DISK LUKS, use 'lsblk -f' ou 'blkid' para verificar.
# Se seus discos LUKS não tem label, usaremos UUIDs detectados.
declare -A DISKS
DISKS["Data"]="crypt_data|/mnt/data|ext4"
DISKS["Projects"]="crypt_projects|/mnt/projects|ext4"
DISKS["Backup"]="crypt_backup|/mnt/backup_btrfs|btrfs"

if [[ $EUID -ne 0 ]]; then
   err "Este script precisa ser rodado como root (sudo)."
fi

log "Iniciando configuração de discos criptografados (Auto-Unlock via Keyfile)..."

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

configure_disk() {
    local label=$1
    local config=$2
    
    IFS='|' read -r mapper_name mount_point fs_type <<< "$config"
    
    log "Processando disco: $label -> $mount_point ($fs_type)"

    # 1. Encontrar UUID da partição LUKS pai
    # O Label "Data" está no filesystem (ext4) DENTRO do container criptografado.
    # Precisamos achar o dispositivo pai (crypto_LUKS) desse filesystem.
    
    # Busca o device path associado ao Label (ex: /dev/mapper/crypt_data)
    local dev_path=$(blkid -L "$label")
    
    if [ -z "$dev_path" ]; then
        # Se não achou pelo label (talvez não esteja montado/aberto), tenta achar pelo device físico se o label fosse do LUKS
        # Fallback simples ou aviso
        warn "Label '$label' não encontrado em nenhum dispositivo ativo/montado."
        warn "Certifique-se que o disco está descriptografado manualmente pelo menos uma vez para configuração inicial."
        return
    fi
    
    # Descobre o parent físico (o container LUKS)
    # lsblk -n -o PKNAME,FSTYPE /dev/mapper/crypt_data -> (null) se for direto, ou o nome do device slave
    # Jeito mais robusto: procurar quem é o holder ou slave
    
    # Se o device for /dev/mapper/..., precisamos achar o device físico subjacente
    # Ex: /dev/mapper/crypt_data -> /dev/dm-0 -> slave é /dev/sdb1
    
    # Pega o nome do kernel do dispositivo mapeado
    local kname=$(lsblk -no KNAME "$dev_path") 
    
    # Pega os slaves (os dispositivos físicos abaixo dele)
    local parent_dev=$(lsblk -no PKNAME "/dev/$kname" | head -n1)
    
    if [ -z "$parent_dev" ]; then
         warn "Não foi possível determinar o dispositivo pai de $dev_path"
         return
    fi
    
    # Pega o UUID desse pai
    local uuid=$(lsblk -no UUID "/dev/$parent_dev")
    
    if [ -z "$uuid" ]; then
        warn "UUID não encontrado para o dispositivo pai /dev/$parent_dev."
        return
    fi

    log "UUID detectado: $uuid"
    local keyfile="$KEY_DIR/${mapper_name}.key"

    # 2. Gerar Keyfile se não existir
    if [ ! -f "$keyfile" ]; then
        log "Gerando keyfile segura para $mapper_name..."
        dd if=/dev/urandom of="$keyfile" bs=1024 count=4 status=none
        chmod 400 "$keyfile"
        
        warn "ATENÇÃO: Uma nova chave foi gerada em $keyfile."
        warn "Você precisa autorizar essa chave no disco AGORA."
        echo "Rodando: cryptsetup luksAddKey /dev/disk/by-uuid/$uuid $keyfile"
        cryptsetup luksAddKey "/dev/disk/by-uuid/$uuid" "$keyfile"
        
        if [ $? -eq 0 ]; then
            log "Chave adicionada com sucesso ao slot LUKS!"
        else
            err "Falha ao adicionar chave. Verifique sua senha."
        fi
    else
        log "Keyfile já existe em $keyfile. Assumindo que já está autorizada."
    fi

    # 3. Configurar /etc/crypttab
    if ! grep -q "$mapper_name" /etc/crypttab; then
        log "Adicionando entrada ao /etc/crypttab..."
        # UUID=... mapper_name /path/to/key luks,discard
        echo "$mapper_name UUID=$uuid $keyfile luks,discard" >> /etc/crypttab
    else
        log "Entrada já existe no /etc/crypttab."
    fi

    # 4. Configurar /etc/fstab
    mkdir -p "$mount_point"
    
    if ! grep -q "$mount_point" /etc/fstab; then
        log "Adicionando entrada ao /etc/fstab..."
        # /dev/mapper/name mount_point fs_type defaults,noatime,nofail 0 2
        
        # Opções específicas por FS
        local opts="defaults,noatime,nofail"
        if [ "$fs_type" == "btrfs" ]; then
            opts="defaults,noatime,compress=zstd,nofail"
        fi

        echo "/dev/mapper/$mapper_name $mount_point $fs_type $opts 0 2" >> /etc/fstab
    else
        log "Entrada já existe no /etc/fstab."
    fi
    
    log "Configuração de $label concluída!"
    echo "---------------------------------------------------"
}

# Iterar sobre os discos configurados
for label in "${!DISKS[@]}"; do
    configure_disk "$label" "${DISKS[$label]}"
done

log "Processo finalizado."
log "Execute 'systemctl daemon-reload' e tente montar com 'mount -a' ou reinicie para testar."
