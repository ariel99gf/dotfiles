#!/bin/bash
set -e

echo "### Iniciando Configuração Pessoal (Perfil DevOps) sobre o Omarchy ###"

# --- 1. Limpeza de Bloatware ---
echo "--> Removendo pacotes gráficos não utilizados..."
# Lista de remoção:
# - spotify: Bloat (Usa YouTube Music)
# - 1password: Bloat (Usa Bitwarden)
# - obsidian: Redundante (Usa Neovim)
# - signal-desktop: Não usa
# - typora: Redundante (Usa Neovim para Markdown)
PACKAGES_TO_REMOVE=(
    spotify
    1password-beta
    1password-cli
    obsidian
    signal-desktop
    typora
    libreoffice-fresh
)
# O comando || true impede que o script pare se algum pacote já não estiver lá
sudo pacman -Rns --noconfirm "${PACKAGES_TO_REMOVE[@]}" || true
echo "Pacotes removidos com sucesso."

# --- 2. Instalação de Aplicativos Pessoais ---
echo "--> Instalando aplicativos essenciais via Yay..."
# NOTA: LocalSend já vem instalado no Omarchy.
yay -S --noconfirm --needed \
  brave-bin \
  bitwarden \
  bitwarden-cli \
  tmux \
  lazydocker \
  lazygit \
  timr

# --- 3. Instalação do YouTube Music (WebApp Nativo) ---
echo "--> Configurando YouTube Music como WebApp..."
curl -o "$HOME/.local/share/icons/youtube-music.png" "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Youtube_Music_icon.svg/2048px-Youtube_Music_icon.svg.png"
omarchy-webapp-install "https://music.youtube.com" "YouTube Music" "youtube-music"

# Google Suite (Usando ícones de documento do sistema para consistência)
echo "--> Instalando Google Sheets, Docs e Slides..."
omarchy-webapp-install "https://docs.google.com/spreadsheets" "Google Sheets" "application-vnd.oasis.opendocument.spreadsheet"
omarchy-webapp-install "https://docs.google.com/document" "Google Docs" "application-vnd.oasis.opendocument.text"
omarchy-webapp-install "https://docs.google.com/presentation" "Google Slides" "application-vnd.oasis.opendocument.presentation"

# Instala o atalho do Pomodoro (Janela Flutuante)
# Sintaxe: omarchy-tui-install "Nome" "Comando" "Estilo" "URL_Icone"
omarchy-tui-install "Pomodoro" "timr -m pomodoro -w 50:00 -p 10:00 -n on" float "https://cdn-icons-png.flaticon.com/512/2928/2928956.png"

# --- 4. Configuração de Rede (Tailscale) ---
echo "--> Instalando e Configurando Tailscale..."
omarchy-install-tailscale
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
echo "--> Configurando linguagens..."
omarchy-install-dev-env node
omarchy-install-dev-env python
omarchy-install-dev-env go

# Java (Versão específica para Backend legado/compatibilidade)
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

if [ ! -d "$DOTFILES_DIR" ]; then
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  cd "$DOTFILES_DIR" && git pull && cd "$HOME"
fi

cd "$DOTFILES_DIR"
echo "--> Linkando configurações do Tmux..."
stow --adopt -vSt ~ tmux

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
