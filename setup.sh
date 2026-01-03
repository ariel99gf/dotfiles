#!/bin/bash
set -e

# --- Funções Auxiliares e Logs ---
log() { echo -e "\n--> $1"; }
warn() { echo -e "⚠️  $1"; }

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
  tailscale freerdp openbsd-netcat gum

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
sudo cp "$HOME/Work/dotfiles/system-files/etc/sysctl.d/99-devops.conf" /etc/sysctl.d/99-devops.conf
sudo sysctl --system >/dev/null

# Bitwarden SSH Agent (Bashrc)
if ! grep -q "SSH_AUTH_SOCK.*bitwarden" "$HOME/.bashrc"; then
    echo 'export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"' >> "$HOME/.bashrc"
    export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
fi

# --- 4. Ambiente de Desenvolvimento (Mise) ---
log "Configurando Ambiente Dev (Mise)..."
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
stow --dir="$HOME/Work/dotfiles" --target="$HOME" --adopt -vSt ~ tmux bin systemd || true
# Garante que a versão do repositório prevaleça sobre a local adotada
cd "$HOME/Work/dotfiles" && git restore . && cd - > /dev/null

# Git Identity & Signing
git config --global user.name "Ariel F."
git config --global user.email "50802265+ariel99gf@users.noreply.github.com"
git config --global gpg.format ssh
git config --global commit.gpgsign true

# Tenta detectar chave SSH do agente (Bitwarden deve estar desbloqueado)
SSH_KEY=$(ssh-add -L 2>/dev/null | head -n1 | awk '{print $2}')
if [ -n "$SSH_KEY" ]; then
    git config --global user.signingkey "$SSH_KEY"
    log "Git configurado para assinar com chave detectada."
else
    warn "Nenhuma chave SSH encontrada no agente. Configure 'user.signingkey' manualmente após desbloquear o Bitwarden."
fi

# Alias de Backup
grep -q "alias backup-now" "$HOME/.bashrc" || echo "alias backup-now='sudo btrbk -c /etc/btrbk/btrbk.conf run && $HOME/backup-data-ext4.sh'" >> "$HOME/.bashrc"

# Projetos de Trabalho
mkdir -p "$HOME/Work/Clients"
declare -A REPOS=(
    ["albastore"]="git@github.com:ariel99gf/albastore.git"
    ["ariel99gf"]="git@github.com:ariel99gf/ariel99gf.git"
    ["nextjs-commerce"]="git@github.com:ariel99gf/nextjs-commerce.git"
    ["my-note-app"]="git@github.com:ariel99gf/my-note-app.git"
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
