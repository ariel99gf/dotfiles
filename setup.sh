#!/bin/bash
set -e

# --- Funções Auxiliares e Logs ---
log() { echo -e "\n--> $1"; }
warn() { echo -e "⚠️  $1"; }

# Detecta diretório dos dotfiles (assume diretório atual ou padrão)
DOTFILES_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [[ "$DOTFILES_DIR" != *"/dotfiles"* ]]; then
    DOTFILES_DIR="$HOME/Work/dotfiles"
fi

# Tratamento de Erro (Diagnóstico)
error_handler() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo -e "\n❌ Erro detectado no setup (Exit Code: $exit_code)."
        if command -v omarchy-debug &>/dev/null; then
            if gum confirm "Deseja rodar o omarchy-debug para diagnosticar o sistema?"; then
                omarchy-debug
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
log "Gerenciando Pacotes..."

# Remove Bloatware
PKGS_REM=(spotify 1password-beta 1password-cli obsidian signal-desktop typora libreoffice-fresh)
for pkg in "${PKGS_REM[@]}"; do remove_installed "$pkg"; done

# Instalação Unificada (Apps Pessoais + Tailscale + Deps de VM)
log "Instalando aplicativos e ferramentas..."
yay -S --noconfirm --needed \
  brave-bin bitwarden bitwarden-cli tmux lazydocker lazygit stow timr \
  tailscale rancher-desktop freerdp openbsd-netcat gum python-pipx \
  ttf-jetbrains-mono-nerd btrbk \
  eza bat zoxide ripgrep fd httpie stern trivy k6

# --- 2. WebApps & TUI ---
log "Configurando WebApps..."

# Função Wrapper para usar o padrão do Omarchy
install_webapp() {
    # Usage: install_webapp "Name" "URL" "Icon_URL_or_Path" "MimeTypes"
    omarchy-webapp-install "$1" "$2" "$3" "" "$4"
}

# YouTube Music (Baixa ícone automaticamente via script)
install_webapp "YouTube Music" "https://music.youtube.com" "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/2048px-Youtube_Music_icon.svg.png"

# Google Suite (Usando ícones genéricos do sistema ou URLs estáveis se preferir)
# Como o script omarchy espera um arquivo em ~/.local/share/applications/icons se não for URL,
# vamos usar URLs de ícones para garantir que funcione sem dependências locais prévias.
install_webapp "Google Sheets" "https://docs.google.com/spreadsheets" "https://cdn-icons-png.flaticon.com/512/2965/2965327.png" "application-vnd.oasis.opendocument.spreadsheet"
install_webapp "Google Docs" "https://docs.google.com/document" "https://cdn-icons-png.flaticon.com/512/5968/5968517.png" "application-vnd.oasis.opendocument.text"
install_webapp "Google Slides" "https://docs.google.com/presentation" "https://cdn-icons-png.flaticon.com/512/2965/2965330.png" "application-vnd.oasis.opendocument.presentation"

# Pomodoro TUI
if command -v omarchy-tui-install &>/dev/null; then
    omarchy-tui-install "Pomodoro" "timr -m pomodoro -w 50:00 -p 10:00 -n on" float "https://cdn-icons-png.flaticon.com/512/2928/2928956.png" || warn "Falha ao instalar Pomodoro TUI."
fi

# --- 3. Configurações de Sistema ---
log "Configurando Sistema (Tailscale, Kernel, SSH)..."

# Tailscale
command -v omarchy-install-tailscale &>/dev/null && omarchy-install-tailscale || sudo systemctl enable --now tailscaled

# Kernel Tuning (DevOps)
if [ -f "$DOTFILES_DIR/system-files/etc/sysctl.d/99-devops.conf" ]; then
    sudo cp "$DOTFILES_DIR/system-files/etc/sysctl.d/99-devops.conf" /etc/sysctl.d/99-devops.conf
    sudo sysctl --system >/dev/null
else
    warn "Arquivo de tuning do kernel não encontrado em $DOTFILES_DIR"
fi

# Configura o carregamento do .bash_aliases se não existir
if ! grep -q ".bash_aliases" "$HOME/.bashrc"; then
    log "Configurando .bashrc para carregar .bash_aliases..."
    echo '[ -f ~/.bash_aliases ] && . ~/.bash_aliases' >> "$HOME/.bashrc"
fi

# --- 4. Ambiente de Desenvolvimento (Mise) ---
log "Configurando Ambiente Dev (Mise)..."

export MISE_FETCH_REMOTE_VERSIONS_TIMEOUT=30s

eval "$(mise activate bash)" || warn "Mise não ativado na sessão atual."

# Linguagens e Ferramentas
for lang in node python go; do 
    command -v omarchy-install-dev-env &>/dev/null && omarchy-install-dev-env "$lang"
done

mise use --global java@temurin-21 \
    terraform@latest kubectl@latest k9s@latest helm@latest \
    ansible@latest awscli@latest jq@latest yq@latest

# --- 5. Dotfiles & Git ---
log "Sincronizando Dotfiles e Git..."
mkdir -p "$HOME/Work"
[ ! -d "$HOME/Work/dotfiles" ] && git clone "git@github.com:ariel99gf/dotfiles.git" "$HOME/Work/dotfiles"

# Instala o Tmux Plugin Manager (TPM)
[ ! -d "$HOME/.tmux/plugins/tpm" ] && git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

stow --dir="$HOME/Work/dotfiles" --target="$HOME" --adopt -vSt tmux bin systemd backup bash || true
# Garante que a versão do repositório prevaleça sobre a local adotada
cd "$HOME/Work/dotfiles" && git restore . && cd - > /dev/null

# Git Identity & Signing
git config --global user.name "Ariel F."
git config --global user.email "50802265+ariel99gf@users.noreply.github.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true

# Tenta detectar chave SSH do agente (Bitwarden deve estar desbloqueado)
SSH_KEY=$(ssh-add -L 2>/dev/null | head -n1 | awk '{print $1, $2}')
if [ -n "$SSH_KEY" ]; then
    git config --global user.signingkey "$SSH_KEY"
    log "Git configurado para assinar com chave detectada."
else
    warn "Nenhuma chave SSH encontrada no agente. Configure 'user.signingkey' manualmente após desbloquear o Bitwarden."
fi

# Projetos de Trabalho
mkdir -p "$HOME/Work/Clients"
declare -A REPOS=(
    ["albastore"]="git@github.com:ariel99gf/albastore.git"
    ["ariel99gf"]="git@github.com:ariel99gf/ariel99gf.git"
    ["nextjs-commerce"]="git@github.com:ariel99gf/nextjs-commerce.git"
    ["my-node-app"]="git@github.com:ariel99gf/my-node-app.git"
    ["homelab"]="git@github.com:ariel99gf/homelab.git"
    ["My-notes"]="git@github.com:ariel99gf/My-notes.git"
    ["books"]="git@github.com:ariel99gf/books.git"
    ["Scrollytelling-Creating-a-One-Page-Web-Experience"]="git@github.com:ariel99gf/Scrollytelling-Creating-a-One-Page-Web-Experience.git"
    ["practice-it-java-3086189"]="git@github.com:ariel99gf/practice-it-java-3086189.git"
    ["work_old"]="git@github.com:ariel99gf/work_old.git"
    ["work_old1"]="git@github.com:ariel99gf/work_old1.git"
    ["AnhembiMorumbi"]="git@github.com:ariel99gf/AnhembiMorumbi.git"
    ["todo_list"]="git@github.com:ariel99gf/todo_list.git"
    ["albastore-web"]="git@github.com:Lojinha-da-alba/albastore-web.git"
    ["albastore-api"]="git@github.com:Lojinha-da-alba/albastore-api.git"
)
for dir in "${!REPOS[@]}"; do
    [ ! -d "$HOME/Work/$dir" ] && git clone "${REPOS[$dir]}" "$HOME/Work/$dir"
done

# --- 6. Automação de Health Check ---
log "Configurando Health Check Semanal..."
mkdir -p "$HOME/bin" "$HOME/Work/logs" "$HOME/.config/systemd/user"

# Script simplificado (gerenciado via stow)

# Systemd Units (gerenciados via stow)
systemctl --user daemon-reload
systemctl --user enable --now health-check.timer

log "Setup Concluído! Reinicie o sistema para aplicar todas as mudanças."
warn "Lembre-se de verificar o Bitwarden para a chave SSH."
