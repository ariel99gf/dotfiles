#!/bin/bash
set -e

# --- Funções Auxiliares ---

# Função para remover pacote apenas se estiver instalado
remove_if_installed() {
    if pacman -Qi "$1" &> /dev/null; then
        echo "--> Removendo $1..."
        sudo pacman -Rns --noconfirm "$1"
    else
        echo "--> $1 não encontrado. Pulando."
    fi
}

# Função nativa para criar WebApps (Substitui o omarchy-webapp-install quebrado)
# Uso: create_webapp "Nome" "URL" "Icone" "Slug"
create_webapp() {
    local NAME="$1"
    local URL="$2"
    local ICON="$3"
    local SLUG="$4"
    local DESKTOP_FILE="$HOME/.local/share/applications/${SLUG}.desktop"

    echo "--> Criando WebApp: $NAME ($SLUG)..."
    
    # Garante que o diretório de ícones e aplicações existe
    mkdir -p "$HOME/.local/share/applications"
    
    # Cria o arquivo .desktop
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$NAME
Comment=WebApp para $NAME
Exec=brave --app="$URL"
Icon=$ICON
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
EOF

    chmod +x "$DESKTOP_FILE"
    echo "    Atalho criado em: $DESKTOP_FILE"
}

echo "### Iniciando Configuração Pessoal (Perfil DevOps) sobre o Omarchy ###"

# --- 1. Limpeza de Bloatware ---
echo "--> Verificando pacotes para remoção..."
PACKAGES_TO_REMOVE=(
    spotify
    1password-beta
    1password-cli
    obsidian
    signal-desktop
    typora
    libreoffice-fresh
)

for pkg in "${PACKAGES_TO_REMOVE[@]}"; do
    remove_if_installed "$pkg"
done
echo "Limpeza concluída."

# --- 2. Instalação de Aplicativos Pessoais ---
echo "--> Instalando aplicativos essenciais via Yay..."
# Adicionado --needed para evitar reinstalação e warnings
yay -S --noconfirm --needed \
  brave-bin \
  bitwarden \
  bitwarden-cli \
  tmux \
  lazydocker \
  lazygit \
  stow \
  timr

# --- 3. Instalação do YouTube Music e Google Suite (WebApp Nativo) ---
echo "--> Configurando WebApps..."

# Baixa ícone do YT Music
mkdir -p "$HOME/.local/share/icons"
curl -s -o "$HOME/.local/share/icons/youtube-music.png" "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/2048px-Youtube_Music_icon.svg.png"

# Criação dos WebApps usando a função corrigida
# create_webapp "Nome" "URL" "Icone/Caminho" "NomeArquivoSemExtensao"
create_webapp "YouTube Music" "https://music.youtube.com" "$HOME/.local/share/icons/youtube-music.png" "youtube-music"
create_webapp "Google Sheets" "https://docs.google.com/spreadsheets" "application-vnd.oasis.opendocument.spreadsheet" "google-sheets"
create_webapp "Google Docs" "https://docs.google.com/document" "application-vnd.oasis.opendocument.text" "google-docs"
create_webapp "Google Slides" "https://docs.google.com/presentation" "application-vnd.oasis.opendocument.presentation" "google-slides"

# Instala o atalho do Pomodoro (Janela Flutuante)
# Mantive o comando original do omarchy-tui se ele funcionar, senão pode precisar de ajuste similar
omarchy-tui-install "Pomodoro" "timr -m pomodoro -w 50:00 -p 10:00 -n on" float "https://cdn-icons-png.flaticon.com/512/2928/2928956.png" || echo "Aviso: Falha ao instalar atalho TUI do Pomodoro."

# --- 4. Configuração de Rede (Tailscale) ---
echo "--> Instalando e Configurando Tailscale..."
# Adicionado --needed no pacman interno caso o script omarchy não tenha
if command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm --needed tailscale
fi
# Executa o setup do tailscale se o comando específico existir, ou fallback
if command -v omarchy-install-tailscale &> /dev/null; then
    omarchy-install-tailscale
else
    # Fallback manual caso o script omarchy falhe
    sudo systemctl enable --now tailscaled
fi

echo "⚠️  IMPORTANTE: Se o Tailscale não pediu autenticação, rode 'sudo tailscale up' manualmente ao final."

# --- 5. Configuração do Windows VM ---
echo "--> Preparando dependências do Windows VM..."
if [ -e /dev/kvm ]; then
    echo "KVM detectado. Instalando dependências..."
    sudo pacman -S --noconfirm --needed freerdp openbsd-netcat gum
    echo "⚠️  NOTA: Para instalar o Windows, rode 'omarchy-windows-vm install' depois."
else
    echo "⚠️  AVISO: KVM não detectado. Pulei dependências de VM."
fi

# --- 6. Configuração de Dev (DevOps Focus) ---
echo "--> Configurando linguagens (Mise)..."
# Verificação básica para garantir que o mise está carregado
eval "$(mise activate bash)" || echo "Aviso: Não foi possível ativar o mise nesta sessão."

omarchy-install-dev-env node
omarchy-install-dev-env python
omarchy-install-dev-env go

# Java
echo "--> Instalando Java (Temurin 21 LTS)..."
mise use --global java@temurin-21

# --- 7. Configuração do SSH (Bitwarden) ---
echo "--> Configurando Bitwarden SSH Agent..."
if ! grep -q "SSH_AUTH_SOCK.*bitwarden" "$HOME/.bashrc"; then
    echo 'export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"' >> "$HOME/.bashrc"
fi
export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"

# Pausa para login no Bitwarden
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! AÇÃO NECESSÁRIA: Habilitar o Bitwarden SSH Agent           !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "1. Abra o Bitwarden agora."
echo "2. Faça login e vá em Settings -> Security -> Enable SSH Agent."
read -r -p "Pressione ENTER após configurar o Bitwarden..."
echo ""

# --- 8. Dotfiles ---
echo "--> Configurando Dotfiles..."
DOTFILES_DIR="$HOME/Work/dotfiles"
DOTFILES_REPO="git@github.com:ariel99gf/dotfiles.git"

# Garante que a pasta Work existe
mkdir -p "$HOME/Work"

if [ ! -d "$DOTFILES_DIR" ]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  cd "$DOTFILES_DIR" && git pull && cd "$HOME"
fi

cd "$DOTFILES_DIR"
echo "--> Linkando configurações do Tmux..."
stow --adopt -vSt ~ tmux || echo "Aviso: Stow encontrou conflitos ou já estava linkado."

# --- 9. Git Identity ---
echo "--> Configurando Identidade do Git..."
git config --global user.name "Ariel F."
git config --global user.email "50802265+ariel99gf@users.noreply.github.com"

echo "--> Configurando Aliases..."
if ! grep -q "alias backup-now=" "$HOME/.bashrc"; then
    echo "alias backup-now='sudo btrbk -c /etc/btrbk/btrbk.conf run && $HOME/backup-data-ext4.sh'" >> "$HOME/.bashrc"
    echo "   Alias 'backup-now' adicionado ao .bashrc"
else
    echo "   Alias 'backup-now' já configurado."
fi

echo ""
echo "### Configuração DevOps Concluída! ###"
echo "Próximos passos:"
echo "1. Reinicie o sistema."
echo "2. No Neovim, instale o plugin 'epwalsh/obsidian.nvim' para gerenciar suas notas."
