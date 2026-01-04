#!/bin/bash

# Configuração de mapeamento: "Origem|Destino_na_Home"
# Isso permite você mapear pastas de discos diferentes
MAPS=(
    "/mnt/data/*|$HOME"
    "/mnt/projects/Work|$HOME/Work"
)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

log "Iniciando sincronização de links simbólicos..."

for entry in "${MAPS[@]}"; do
    IFS='|' read -r source_pattern target_base <<< "$entry"

    # Expande o glob (o *) de forma segura
    for folder_path in $source_pattern; do
        
        # Verifica se o caminho existe (evita erro se o disco estiver desmontado)
        if [ ! -e "$folder_path" ]; then
            warn "Caminho não encontrado: $folder_path. O disco está montado?"
            continue
        fi

        folder_name=$(basename "$folder_path")
        
        # Pula pastas de sistema e arquivos ocultos
        [[ "$folder_name" == "lost+found" ]] && continue
        [[ "$folder_name" == "*" ]] && continue

        # Se o destino for uma pasta (como $HOME), o link terá o mesmo nome da origem
        # Se o destino for um caminho completo (como $HOME/Work), usamos ele
        if [ -d "$target_base" ] && [ "$(basename "$target_base")" != "$folder_name" ]; then
            target_path="$target_base/$folder_name"
        else
            target_path="$target_base"
        fi

        echo "--- Processando: $folder_name ---"

        # 1. Limpa link quebrado ou antigo
        if [ -L "$target_path" ]; then
            rm "$target_path"
        fi

        # 2. Se for uma pasta real, tenta remover (apenas se estiver vazia)
        if [ -d "$target_path" ] && [ ! -L "$target_path" ]; then
            if ! rmdir "$target_path" 2>/dev/null; then
                err "A pasta '$target_path' não está vazia. Mova os arquivos manualmente."
                continue
            fi
        fi

        # 3. Cria o link
        if ln -s "$folder_path" "$target_path"; then
            log "[SUCESSO] Link criado: $target_path -> $folder_path"
        else
            err "Falha ao criar link para $folder_name"
        fi
    done
done

log "---------------------------------------"
log "Processo finalizado!"
