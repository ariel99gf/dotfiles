#!/bin/bash
set -e

# --- Funções Auxiliares e Logs ---
log() { echo -e "\n--> $1"; }
warn() { echo -e "⚠️  $1"; }

DOTFILES_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [[ "$DOTFILES_DIR" != */dotfiles* ]]; then
    DOTFILES_DIR="$HOME/Work/dotfiles"
fi

error_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n❌ Erro detectado no setup (Exit Code: $exit_code)."
        if command -v omarchy-debug &>/dev/null; then
            if command -v gum &>/dev/null; then
                if gum confirm "Deseja rodar o omarchy-debug para diagnosticar o sistema?"; then
                    omarchy-debug
                fi
            else
                read -p "Deseja rodar o omarchy-debug? [y/N] " response
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
                    omarchy-debug
                fi
            fi
        else
            warn "omarchy-debug não encontrado para diagnóstico."
        fi
    fi
}
trap error_handler EXIT

remove_installed() {
    if pacman -Qi "$1" &> /dev/null; then
        log "Removendo $1..."
        sudo pacman -Rns --noconfirm "$1"
    fi
}

log "### Iniciando Configuração Pessoal (Perfil DevOps) ###"

# --- 1. Limpeza e Instalação Base ---
log "Gerenciando Pacotes e resolvendo conflitos de Node..."

# Remove qualquer versão que não seja a LTS para evitar o conflito
sudo pacman -Rdd --noconfirm nodejs npm nvm 2>/dev/null || true

# Instala a versão que o Rancher Desktop exige ANTES de rodar o yay
sudo pacman -S --needed --noconfirm nodejs-lts-jod yarn

PKGS_REM=(spotify 1password-beta 1password-cli obsidian signal-desktop typora libreoffice-fresh omarchy-chromium)
for pkg in "${PKGS_REM[@]}"; do remove_installed "$pkg"; done

log "Instalando aplicativos via Yay..."
# Removi o nvm daqui, você já tem o Mise!
yay -S --noconfirm --needed \
  brave-bin bitwarden bitwarden-cli tmux stow timr jq \
  tailscale rancher-desktop freerdp openbsd-netcat python-pipx \
  ttf-jetbrains-mono-nerd btrbk

# --- 2. WebApps & TUI ---
log "Configurando WebApps..."

install_webapp() {
    omarchy-webapp-install "$1" "$2" "$3" "" "$4"
}

install_webapp "YouTube Music" "https://music.youtube.com" "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/2048px-Youtube_Music_icon.svg.png"
install_webapp "Google Sheets" "https://docs.google.com/spreadsheets" "https://cdn-icons-png.flaticon.com/512/2965/2965327.png" "application-vnd.oasis.opendocument.spreadsheet"
install_webapp "Google Docs" "https://docs.google.com/document" "https://cdn-icons-png.flaticon.com/512/5968/5968517.png" "application-vnd.oasis.opendocument.text"
install_webapp "Google Slides" "https://docs.google.com/presentation" "https://cdn-icons-png.flaticon.com/512/2965/2965330.png" "application-vnd.oasis.opendocument.presentation"

if command -v omarchy-tui-install &>/dev/null; then
    omarchy-tui-install "Pomodoro" "timr -m pomodoro -w 50:00 -p 10:00 -n on" float "https://cdn-icons-png.flaticon.com/512/2928/2928956.png" || warn "Falha ao instalar Pomodoro TUI."
fi

# --- 3. Configurações de Sistema ---
log "Configurando Sistema (Tailscale, Kernel, SSH)..."

command -v omarchy-install-tailscale &>/dev/null && omarchy-install-tailscale || sudo systemctl enable --now tailscaled

if [ -f "$DOTFILES_DIR/system-files/etc/sysctl.d/99-devops.conf" ]; then
    sudo cp "$DOTFILES_DIR/system-files/etc/sysctl.d/99-devops.conf" /etc/sysctl.d/99-devops.conf
    sudo sysctl --system >/dev/null
else
    warn "Arquivo de tuning do kernel não encontrado em $DOTFILES_DIR"
fi

if ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
    log "Configurando .bashrc para carregar .bash_aliases..."
    echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$HOME/.bashrc"
fi

# --- 4. Ambiente de Desenvolvimento (Mise) ---
log "Configurando Ambiente Dev e CLI Tools (Mise)..."

# 4.1. Configurações de ambiente e chaves GPG
log "Preparando chaves GPG e variáveis de timeout..."
gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 86C8D74642E67846F8E120284DAA80D1E737BC9F || warn "Falha ao importar chave GPG do Node."

export MISE_FETCH_REMOTE_VERSIONS_TIMEOUT=60s
export MISE_HTTP_TIMEOUT=60s
#export MISE_NODE_SKIP_VERIFY=1

eval "$(mise activate bash)" || warn "Mise não ativado na sessão atual."

# 4.2. Instalação das Linguagens Base (Core)
log "Instalando Linguagens Base (Python 3.12, Node LTS, Go, Rust)..."
mise install python@3.12 node@lts go@latest rust@latest
mise use --global python@3.12 node@lts go@latest rust@latest java@temurin-21
# Reseta o cache de binários do mise para garantir que o python@3.12 apareça no PATH
mise reshim

# 4.2.1. Instalação de Ferramentas CLI via Mise
log "Instalando ferramentas utilitárias (CLI)..."
CLI_TOOLS=(
    usage eza bat zoxide ripgrep fd 
    lazygit lazydocker gum stern 
    trivy k6 terraform kubectl k9s helm 
    ansible awscli jq yq pre-commit 
    gitleaks tflint yamllint hadolint
)

# Instala todas de uma vez (mais rápido)
mise use --global "${CLI_TOOLS[@]}"

# 4.3. Instalação Manual do Prowler (Resolução definitiva)
log "Instalando Prowler via Pipx (Forçando Python 3.12)..."

# No Arch/Mise, o binário costuma ficar neste caminho padrão. 
# Tentamos localizar ou usamos o fallback manual.
PYTHON_312_BIN="$HOME/.local/share/mise/installs/python/3.12.12/bin/python"

# Se o caminho acima não existir, tentamos perguntar ao mise de novo de forma bruta
if [ ! -f "$PYTHON_312_BIN" ]; then
    PYTHON_312_BIN=$(mise which python@3.12)
fi

log "Usando Python em: $PYTHON_312_BIN"

if [ -f "$PYTHON_312_BIN" ]; then
    # Limpa qualquer resquício de instalação anterior para evitar erro de 'venv já existe'
    pipx uninstall prowler >/dev/null 2>&1 || true
    
    # Instalamos usando o binário direto
    if pipx install prowler --python "$PYTHON_312_BIN"; then
        log "✅ Prowler instalado com sucesso."
    else
        warn "Falha na instalação do Prowler via pipx. Verifique se o pacote 'python-pipx' está instalado via pacman."
    fi
else
    warn "Binário Python 3.12 não encontrado. Pulando Prowler."
fi

log "Garantindo que binários do Pipx (como prowler) estejam no PATH..."
pipx ensurepath --force

# 4.4. Customização de Ambientes (Pós-Prowler)
# Nota: Se o script estiver nos dotfiles, ele só funcionará na 2ª execução 
# ou se você já tiver rodado o stow anteriormente.
log "Executando customização de linguagens..."
for lang in node python go rust; do
    if command -v omarchy-install-dev-env &>/dev/null; then
        omarchy-install-dev-env "$lang"
    else
        warn "Script omarchy-install-dev-env não encontrado no PATH. Pulando $lang..."
    fi
done

# --- 5. Dotfiles & Git (Configuração SSH via RAM) ---
log "Iniciando sincronização de Dotfiles e Git..."

# 5.1. Autenticação Bitwarden
log "Verificando autenticação no Bitwarden..."
if bw status | grep -q '"status":"unauthenticated"'; then
    warn "Você não está logado no Bitwarden. Por favor, faça login agora."
    bw login
fi

if [ -z "$BW_SESSION" ]; then
    log "Desbloqueando cofre para obter sessão..."
    export BW_SESSION=$(bw unlock --raw)
fi

# 5.2. Carregar chave SSH Omarchy-PC na RAM (Sem tocar o disco)
eval "$(ssh-agent -s)"

if ! grep -q "ssh-agent -s" "$HOME/.bashrc"; then
    log "Configurando ssh-agent para iniciar automaticamente no .bashrc..."
    echo 'eval "$(ssh-agent -s)" > /dev/null' >> "$HOME/.bashrc"
fi
log "Buscando chave SSH 'Omarchy-PC' no Bitwarden..."
SSH_KEY_CONTENT=$(bw get item Omarchy-PC | jq -r '.sshKey.privateKey')

if [ -n "$SSH_KEY_CONTENT" ] && [ "$SSH_KEY_CONTENT" != "null" ]; then
    echo "$SSH_KEY_CONTENT" | tr -d '\r' | ssh-add -
    log "✅ Chave SSH carregada na memória com sucesso!"
    # Aceita o host do github automaticamente para evitar prompts interativos
    ssh -T git@github.com -o StrictHostKeyChecking=accept-new || true
else
    warn "Falha ao obter chave do Bitwarden. Verifique se o item 'Omarchy-PC' existe."
fi

# 5.3. Definição e Clonagem de Repositórios
mkdir -p "$HOME/Work/Clients"
declare -A REPOS=(
    ["dotfiles"]="git@github.com:ariel99gf/dotfiles.git"
    ["albastore"]="git@github.com:ariel99gf/albastore.git"
    ["ariel99gf"]="git@github.com:ariel99gf/ariel99gf.git"
    ["nextjs-commerce"]="git@github.com:ariel99gf/nextjs-commerce.git"
    ["my-node-app"]="git@github.com:ariel99gf/my-node-app.git"
    ["homelab"]="git@github.com:ariel99gf/homelab.git"
    ["My-notes"]="git@github.com:ariel99gf/My-notes.git"
    ["books"]="git@github.com:ariel99gf/books.git"
    ["albastore-web"]="git@github.com:Lojinha-da-alba/albastore-web.git"
    ["albastore-api"]="git@github.com:Lojinha-da-alba/albastore-api.git"
    ["AnhembiMorumbi"]="git@github.com:ariel99gf/AnhembiMorumbi.git"
    ["Scrollytelling-Creating-a-One-Page-Web-Experience"]="git@github.com:ariel99gf/Scrollytelling-Creating-a-One-Page-Web-Experience.git"
    ["practice-it-java-3086189"]="git@github.com:ariel99gf/practice-it-java-3086189.git"
    ["work_old"]="git@github.com:ariel99gf/work_old.git"
    ["work_old1"]="git@github.com:ariel99gf/work_old1.git"
    ["todo_list"]="git@github.com:ariel99gf/todo_list.git"
)

log "Clonando repositórios em ~/Work..."
for dir in "${!REPOS[@]}"; do
    if [ ! -d "$HOME/Work/$dir" ]; then
        git clone "${REPOS[$dir]}" "$HOME/Work/$dir" || warn "Falha ao clonar $dir"
    fi
done

# 5.4. Configuração de Interface (TPM e Stow)
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

STOW_PACKAGES=(tmux bin systemd backup bash starship)
for pkg in "${STOW_PACKAGES[@]}"; do
    log "Aplicando dotfiles para $pkg via Stow..."
    stow --dir="$DOTFILES_DIR" --target="$HOME" --restow --adopt "$pkg"
done

# 5.5. Configurações Finais do Git (Identidade e Assinatura)
git config --global user.name "Ariel F."
git config --global user.email "50802265+ariel99gf@users.noreply.github.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true

# Detecta a chave na RAM para configurar a assinatura automática de commits
SSH_KEY_PUB=$(ssh-add -L 2>/dev/null | head -n1 | awk '{print $1, $2}')
if [ -n "$SSH_KEY_PUB" ]; then
    git config --global user.signingkey "$SSH_KEY_PUB"
    log "Git configurado para assinar commits com a chave SSH da RAM."
fi

# Garante que as mudanças locais nos dotfiles (pelo --adopt) sejam resetadas para o padrão do repo
cd "$DOTFILES_DIR" && git restore . && cd - > /dev/null

# --- 6. Automação de Health Check ---
log "Configurando Health Check Semanal..."
mkdir -p "$HOME/bin" "$HOME/Work/logs" "$HOME/.config/systemd/user"

systemctl --user daemon-reload
systemctl --user enable --now health-check.timer

log "Setup Concluído! Reinicie o sistema para aplicar todas as mudanças."
warn "Lembre-se de verificar o Bitwarden para a chave SSH."
