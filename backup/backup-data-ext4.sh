#!/bin/bash
set -e

# Configurações
BACKUP_DEST="/mnt/backup_btrfs/omarchy_backups/DATA_MIRROR"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

echo "### Iniciando Backup de Dados (EXT4) via Rsync ###"
echo "Destino: $BACKUP_DEST"

# Garante que a pasta de destino existe
sudo mkdir -p "$BACKUP_DEST"

# 1. Backup de PROJETOS (Work)
echo "--> Sincronizando /mnt/projects..."
# -a: archive (mantém permissões/datas)
# -v: verbose
# --delete: remove do backup o que você deletou na origem (espelho exato)
sudo rsync -av --delete /mnt/projects/ "$BACKUP_DEST/projects/"

# 2. Backup de DADOS (Documents, Downloads, etc)
echo "--> Sincronizando /mnt/data..."
sudo rsync -av --delete /mnt/data/ "$BACKUP_DEST/data/"

echo "### Backup de Dados Concluído com Sucesso! ###"
