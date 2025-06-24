#!/bin/bash

# Garante que o script pare em caso de erro
set -e

echo "### Iniciando configuração do Manjaro/Arch ###"

# --- Atualização do Sistema e Chaveiros ---
echo "--> Atualizando chaveiros e sistema base..."
yes | sudo pacman-key --init
yes | sudo pacman-key --populate archlinux manjaro
yes | sudo pacman -S archlinux-keyring manjaro-keyring --noconfirm --needed
yes | sudo pacman -Syuu --noconfirm

# --- Otimização de Espelhos (pacman-mirrors - específico do Manjaro) ---
if command -v pacman-mirrors &>/dev/null; then
  echo "--> Otimizando espelhos do Pacman com pacman-mirrors (Manjaro)..."
  sudo pacman-mirrors --fasttrack && sudo pacman -Syyu --noconfirm
  sudo rm -f /etc/pacman.d/mirrorlist.pacnew
else
  echo "--> pacman-mirrors não encontrado. Pulando otimização de espelhos (pode não ser Manjaro)."
  sudo pacman -Syy --noconfirm
fi

# --- Preparação para Conflitos: Remover pacotes conflitantes ---
echo "--> Verificando e removendo 'jack2' se estiver instalado..."
if sudo pacman -Qs jack2 &>/dev/null; then
  if yes | sudo pacman -Rdd jack2 --noconfirm; then
    echo "--> 'jack2' removido com sucesso."
  else
    echo "--> AVISO: Falha ao remover 'jack2'."
    exit 1
  fi
else
  echo "--> 'jack2' não está instalado."
fi

echo "--> Verificando e removendo 'fzf-git' se estiver instalado..."
if sudo pacman -Qs fzf-git &>/dev/null; then
  if yes | sudo pacman -Rdd fzf-git --noconfirm; then
    echo "--> 'fzf-git' removido com sucesso."
  else
    echo "--> AVISO: Falha ao remover 'fzf-git'."
    exit 1
  fi
else
  echo "--> 'fzf-git' não está instalado."
fi

# --- Instalação do Yay (AUR Helper) ---
echo "--> Instalando Yay (AUR Helper)..."
if ! command -v yay &>/dev/null; then
  echo "--> Yay não encontrado. Instalando a partir do AUR..."
  BUILD_DIR=$(mktemp -d)
  echo "--> Usando diretório temporário para build: $BUILD_DIR"
  yes | sudo pacman -S --noconfirm --needed git base-devel
  git clone https://aur.archlinux.org/yay-git.git "$BUILD_DIR/yay-git"
  cd "$BUILD_DIR/yay-git"
  makepkg -si --noconfirm
  cd "$HOME"
  echo "--> Limpando diretório temporário de build..."
  rm -rf "$BUILD_DIR"
  echo "--> Yay instalado com sucesso."
else
  echo "--> Yay já está instalado."
fi

# --- Instalação de Pacotes do AUR via Yay ---
echo "--> Instalando pacotes do AUR via Yay..."
yay -S --noconfirm --needed mise tofi

# --- Instalação de Linguagens de Programação com Mise ---
echo "--> Configurando e instalando linguagens com Mise..."
export PATH="$HOME/.local/share/mise/shims:$PATH"
echo "--> Instalando Go, Python e Node.js..."
mise use -g go@latest
mise use -g python@latest
mise use -g node@latest
echo "--> Instalando pacotes globais do Node.js (ex: typescript)..."
npm i -g typescript

# --- Instalação de Pacotes Essenciais e Ferramentas ---
echo "--> Instalando pacotes essenciais e ferramentas via Pacman..."
yes | sudo pacman -S --noconfirm --needed \
  base-devel git git-delta neovim zsh stow tmux fzf ripgrep fd bat eza zoxide \
  docker docker-compose kubectl minikube wget curl unzip tar gzip htop bottom broot \
  ttf-jetbrains-mono-nerd noto-fonts-emoji openssh polkit-kde-agent \
  waybar hyprland xdg-desktop-portal-hyprland swaybg grim slurp wl-clipboard cliphist wofi mako \
  thunar gvfs tumbler ffmpegthumbnailer thunar-archive-plugin \
  bluez bluez-utils blueman \
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol \
  brightnessctl network-manager-applet ghostty timeshift

### Instalação e Configuração do LazyVim
echo "--> Iniciando instalação do LazyVim..."

echo "--> Fazendo backup dos arquivos atuais do Neovim (se existirem)..."
# required
if [ -d "$HOME/.config/nvim" ]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak_$(date +%Y%m%d%H%M%S)"
  echo "    Backup de ~/.config/nvim criado."
fi

# optional but recommended
if [ -d "$HOME/.local/share/nvim" ]; then
  mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak_$(date +%Y%m%d%H%M%S)"
  echo "    Backup de ~/.local/share/nvim criado."
fi
if [ -d "$HOME/.local/state/nvim" ]; then
  mv "$HOME/.local/state/nvim" "$HOME/.local/state/nvim.bak_$(date +%Y%m%d%H%M%S)"
  echo "    Backup de ~/.local/state/nvim criado."
fi
if [ -d "$HOME/.cache/nvim" ]; then
  mv "$HOME/.cache/nvim" "$HOME/.cache/nvim.bak_$(date +%Y%m%d%H%M%S)"
  echo "    Backup de ~/.cache/nvim criado."
fi

echo "--> Clonando o starter do LazyVim..."
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

echo "--> Removendo a pasta .git do LazyVim..."
rm -rf "$HOME/.config/nvim/.git"

echo "--> LazyVim instalado com sucesso!"

# --- Configuração do Flatpak e Instalação de Aplicativos ---
echo "--> Instalando e Configurando Flatpak..."
yes | sudo pacman -S flatpak --noconfirm --needed
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# Instalação do Brave Browser
echo "--> Instalando Brave Browser via Flatpak..."
flatpak install flathub com.brave.Browser -y
# Instalação do Bitwarden
echo "--> Instalando Bitwarden via Flatpak..."
flatpak install flathub com.bitwarden.desktop -y
# Instalação do Ente Auth
echo "--> Instalando Ente Auth via Flatpak..."
flatpak install flathub io.ente.auth -y
# Instalação do Obsidian
echo "--> Instalando Obsidian via Flatpak..."
flatpak install flathub md.obsidian.Obsidian -y

# --- Guia Interativo para Configuração da Chave SSH ---
echo "--> Configurando chave SSH para GitHub..."
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_KEY_PUB_PATH="$SSH_KEY_PATH.pub"

mkdir -p "$HOME/.ssh"

echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! AÇÃO NECESSÁRIA: Configure sua chave SSH existente do Bitwarden.           !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "1. Abra o aplicativo Bitwarden (que acabamos de instalar)."
echo "2. Faça login e encontre sua chave SSH."
echo "3. Crie e cole sua CHAVE PRIVADA no arquivo: $SSH_KEY_PATH"
echo "4. Crie e cole sua CHAVE PÚBLICA no arquivo:  $SSH_KEY_PUB_PATH"
echo ""
read -r -p "Pressione ENTER após ter salvo os dois arquivos (chave privada e pública)..."

if [ ! -f "$SSH_KEY_PATH" ] || [ ! -f "$SSH_KEY_PUB_PATH" ]; then
  echo "--> ERRO: Arquivo de chave privada ou pública não encontrado."
  exit 1
fi

echo "--> Arquivos de chave encontrados. Configurando permissões corretas..."
chmod 700 "$HOME/.ssh"
chmod 600 "$SSH_KEY_PATH"
chmod 644 "$SSH_KEY_PUB_PATH"
echo "--> Permissões configuradas com sucesso."
echo ""
echo "--> Agora, teste a sua conexão com o GitHub executando o seguinte comando em outro terminal:"
echo "    ssh -T git@github.com"
echo ""
read -r -p "Pressione ENTER após testar a conexão e confirmar que funciona..."
echo ""

# --- Clonar e Configurar Dotfiles com Stow ---
echo "--> Clonando repositório de dotfiles de ariel99gf..."
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="git@github.com:ariel99gf/dotfiles.git"
SKIP_STOW=false

if [ -d "$DOTFILES_DIR" ]; then
  if [ -d "$DOTFILES_DIR/.git" ]; then
    echo "--> É um repositório git. Tentando atualizar (git pull)..."
    cd "$DOTFILES_DIR"
    if git pull; then
      echo "--> Repositório atualizado com sucesso."
    else
      echo "--> AVISO: Falha ao atualizar o repositório."
    fi
    cd "$HOME"
  else
    echo "--> '$DOTFILES_DIR' existe mas não é um repositório git. Renomeando e clonando novamente."
    mv "$DOTFILES_DIR" "$DOTFILES_DIR.bak_$(date +%Y%m%d%H%M%S)"
    if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
      echo "--> ERRO: Falha ao clonar o repositório."
      SKIP_STOW=true
    fi
  fi
else
  echo "--> Clonando o repositório '$DOTFILES_REPO'..."
  if ! git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
    echo "--> ERRO: Falha ao clonar o repositório."
    SKIP_STOW=true
  fi
fi

if [ "$SKIP_STOW" = false ] && [ -d "$DOTFILES_DIR" ]; then
  echo "--> Configurando dotfiles com Stow..."
  cd "$DOTFILES_DIR"
  STOW_DIRS=(gitconf tmux zsh hypr waybar dunst wlogout tofi assets)

  echo "--> Criando links para: ${STOW_DIRS[*]}"
  # -v (verbose), -S (stow), -t ~ (target é o diretório home)
  # Adicionado --adopt para tentar resolver conflitos movendo arquivos existentes
  if stow --adopt -vSt ~ "${STOW_DIRS[@]}"; then
    echo "--> Links simbólicos (stow) criados/adotados com sucesso para ${STOW_DIRS[*]}."
  else
    echo "--> AVISO: Ocorreram erros ao executar o stow para ${STOW_DIRS[*]}. Verifique as mensagens acima."
  fi

  # Removido o tratamento especial para nvim, pois o LazyVim já foi instalado
  # e a intenção é usar a configuração padrão do LazyVim diretamente.
  echo "--> Nota: A configuração do Neovim (LazyVim) já foi tratada anteriormente."

  cd "$HOME"
else
  echo "--> Pulando configuração com Stow."
fi

### Configurações Finais
echo "--> Configurando Docker..."
sudo groupadd docker || true # Adiciona '|| true' para não parar o script se o grupo já existir
sudo usermod -aG docker "$USER"
sudo systemctl enable docker.service
sudo systemctl start docker.service

echo "--> Configurando Zsh como shell padrão..."
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
  echo "--> Zsh definido como shell padrão. Faça logout e login para aplicar."
else
  echo "--> Zsh já é o shell padrão."
fi

echo "--> Baixando Antigen para Zsh..."
curl -L git.io/antigen > "$HOME/.antigen.zsh"
echo "--> Antigen baixado com sucesso em '$HOME/antigen.zsh'."

echo ""
echo "### Configuração Concluída! ###"
echo ""
echo "Próximos passos recomendados:"
echo "1. **Reiniciar o sistema** ou fazer **logout e login**."
echo "2. **Configurar o Zsh para usar Antigen:** Adicione 'source ~/antigen.zsh' e a configuração dos seus plugins Zsh ao seu arquivo ~/.zshrc."
echo "3. Explorar os aplicativos instalados: Brave Browser, Bitwarden, Ente Auth, etc."
echo "4. **Verificar Dotfiles:** Confirme se os links simbólicos foram criados corretamente em seu diretório home (para gitconf, tmux, zsh) e em ~/.config (para nvim). **Lembre-se que o Neovim agora usa a configuração do LazyVim.**"
echo "5. **Configurar o Timeshift:** Abra o Timeshift (procure no menu de aplicativos ou execute 'timeshift-launcher' no terminal) e configure os backups do sistema."
echo "6. **Abrir o Neovim:** Execute 'nvim'. Se a configuração foi linkada corretamente, ele deve carregar suas configurações. Use :Lazy (ou o comando do seu gerenciador) para instalar plugins."
echo "7. **Abrir o Tmux:** Execute 'tmux'. Se a configuração foi linkada, ele deve carregar suas configurações. Use o prefixo + I (geralmente Ctrl+b + I) para instalar plugins do TPM, se configurado."
echo "8. **Configurar o Minikube/Kubectl:** Siga a documentação para iniciar o Minikube ('minikube start') ou configurar o kubectl para conectar ao seu cluster."
echo "9. **Configurar o Hyprland:** Edite os arquivos em ~/.config/hypr/, ~/.config/waybar/, etc., conforme necessário."
echo "10. **Iniciar o Hyprland:** Use um Display Manager (como SDDM, GDM, Ly) ou inicie manualmente a partir do TTY (geralmente executando 'Hyprland')."
echo "11. **Verificar Agente Polkit:** Certifique-se de que '/usr/lib/polkit-kde-authentication-agent-1' (ou outro agente) está sendo iniciado com sua sessão Hyprland."
echo "12. **Explorar Novos Aplicativos:** Lembre-se que Ghostty (terminal), Timeshift (backup) e Zen Browser (navegador via Flatpak) foram instalados."
