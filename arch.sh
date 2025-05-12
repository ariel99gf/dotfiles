#!/bin/bash

# Garante que o script pare em caso de erro
set -e

echo "### Iniciando configuração do Manjaro/Arch ###"

# --- Atualização do Sistema e Chaveiros ---
echo "--> Atualizando chaveiros e sistema base..."
# Inicializa e popula o chaveiro do pacman
yes | sudo pacman-key --init
yes | sudo pacman-key --populate archlinux manjaro # Adiciona manjaro para sistemas Manjaro
# Atualiza o chaveiro do Arch (e Manjaro se aplicável)
yes | sudo pacman -S archlinux-keyring manjaro-keyring --noconfirm --needed
# Sincroniza e atualiza completamente o sistema
yes | sudo pacman -Syuu --noconfirm

# --- Otimização de Espelhos (pacman-mirrors - específico do Manjaro) ---
# Verifica se pacman-mirrors existe antes de tentar usá-lo
if command -v pacman-mirrors &> /dev/null; then
    echo "--> Otimizando espelhos do Pacman com pacman-mirrors (Manjaro)..."
    # Atualiza para os espelhos mais rápidos e sincroniza
    sudo pacman-mirrors --fasttrack && sudo pacman -Syyu --noconfirm
    # Remove o arquivo .pacnew gerado, se existir
    sudo rm -f /etc/pacman.d/mirrorlist.pacnew
else
    echo "--> pacman-mirrors não encontrado. Pulando otimização de espelhos (pode não ser Manjaro)."
    # Apenas sincroniza os bancos de dados em sistemas não-Manjaro
    sudo pacman -Syy --noconfirm
fi

# --- Preparação para Conflitos: Remover pacotes conflitantes ---

# Remover jack2 se existir (conflita com pipewire-jack)
echo "--> Verificando e removendo 'jack2' se estiver instalado (conflita com pipewire-jack)..."
if sudo pacman -Qs jack2 &>/dev/null; then
    echo "--> Pacote 'jack2' encontrado. Tentando remover..."
    if yes | sudo pacman -Rdd jack2 --noconfirm; then
        echo "--> 'jack2' removido com sucesso."
    else
        echo "--> AVISO: Falha ao remover 'jack2'. A instalação pode falhar. Remova manualmente ('sudo pacman -Rdd jack2') e tente novamente."
        exit 1 # Sai do script se não conseguir remover o conflito
    fi
else
    echo "--> 'jack2' não está instalado. Nenhuma remoção necessária."
fi

# Remover fzf-git se existir (conflita com fzf)
echo "--> Verificando e removendo 'fzf-git' se estiver instalado (conflita com fzf)..."
if sudo pacman -Qs fzf-git &>/dev/null; then
    echo "--> Pacote 'fzf-git' encontrado. Tentando remover..."
    if yes | sudo pacman -Rdd fzf-git --noconfirm; then
        echo "--> 'fzf-git' removido com sucesso."
    else
        echo "--> AVISO: Falha ao remover 'fzf-git'. A instalação pode falhar. Remova manualmente ('sudo pacman -Rdd fzf-git') e tente novamente."
        exit 1 # Sai do script se não conseguir remover o conflito
    fi
else
    echo "--> 'fzf-git' não está instalado. Nenhuma remoção necessária."
fi

# --- Instalação de Pacotes Essenciais e Ferramentas ---
echo "--> Instalando pacotes essenciais e ferramentas via Pacman..."
# Lista de pacotes a serem instalados.
yes | sudo pacman -S --noconfirm --needed \
    base-devel \
    git \
    neovim \
    zsh \
    stow \
    tmux \
    fzf \
    ripgrep \
    fd \
    bat \
    eza \
    zoxide \
    docker \
    docker-compose \
    kubectl \
    minikube \
    wget \
    curl \
    unzip \
    tar \
    gzip \
    htop \
    bottom \
    broot \
    go \
    python \
    python-pip \
    nodejs \
    npm \
    typescript \
    ttf-jetbrains-mono-nerd \
    noto-fonts-emoji \
    openssh \
    polkit-kde-agent \
    waybar \
    hyprland \
    xdg-desktop-portal-hyprland \
    swaybg \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    wofi \
    mako \
    thunar \
    gvfs \
    tumbler \
    ffmpegthumbnailer \
    thunar-archive-plugin \
    bluez \
    bluez-utils \
    blueman \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    brightnessctl \
    network-manager-applet \
    ghostty \
    timeshift

# --- Instalação do Yay (AUR Helper) ---
echo "--> Instalando Yay (AUR Helper)..."
# Verifica se o diretório /opt existe, se não, tenta criar
if [ ! -d "/opt" ]; then
    echo "--> Criando diretório /opt..."
    sudo mkdir /opt
    sudo chown $USER:$USER /opt # Garante que o usuário atual tenha permissão
fi
# Clona e instala o yay se ainda não estiver instalado
if ! command -v yay &> /dev/null; then
    cd /opt
    git clone https://aur.archlinux.org/yay-git.git
    cd yay-git
    makepkg -si --noconfirm
    cd "$HOME" # Volta para o diretório home
else
    echo "--> Yay já está instalado."
fi

# --- Instalação de Pacotes do AUR via Yay ---
echo "--> Instalando pacotes do AUR via Yay..."
yay -S --noconfirm --needed \
    mise \
    google-chrome # Exemplo, adicione outros pacotes AUR aqui

# --- Configuração do Flatpak e Instalação do Zen Browser ---
echo "--> Instalando e Configurando Flatpak..."
# Instala o Flatpak
yes | sudo pacman -S flatpak --noconfirm --needed
# Adiciona o repositório Flathub (essencial para a maioria dos apps)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "--> Instalando Zen Browser via Flatpak (ID: app.zen_browser.zen)..."
# Instala o Zen Browser via Flatpak, -y para não pedir confirmação
flatpak install flathub app.zen_browser.zen -y

# --- Configuração do Docker ---
echo "--> Configurando Docker..."
# Adiciona o usuário atual ao grupo docker
sudo usermod -aG docker $USER
# Habilita e inicia o serviço Docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

# --- Configuração do Zsh como Shell Padrão ---
echo "--> Configurando Zsh como shell padrão..."
# Verifica se o Zsh já é o shell padrão
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh
    echo "--> Zsh definido como shell padrão. Faça logout e login para aplicar."
else
    echo "--> Zsh já é o shell padrão."
fi

# --- Geração de Chave SSH ED25519 ---
# Gera chave SSH ED25519 se não existir
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "--> Gerando chave SSH ED25519..."
    # Cria o diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Gera a chave sem passphrase
    ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "$(whoami)@$(hostname)-$(date -I)"
    chmod 600 "$HOME/.ssh/id_ed25519"
    chmod 644 "$HOME/.ssh/id_ed25519.pub"
    echo "--> Chave SSH gerada em ~/.ssh/id_ed25519"
    echo "--> Chave Pública:"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    echo "--> Chave SSH ED25519 já existe em ~/.ssh/id_ed25519."
fi

# --- Mensagens Finais e Próximos Passos ---
echo ""
echo "### Configuração Concluída! ###"
echo ""
echo "Próximos passos recomendados:"
echo "1. **Reiniciar o sistema** ou fazer **logout e login** para que todas as alterações tenham efeito (especialmente a adição ao grupo 'docker' e a mudança de shell para Zsh)."
echo "2. **Configurar Dotfiles:** Se você usa 'stow' e tem dotfiles em um repositório, clone-o e use 'stow' para criar os links simbólicos (ex: cd ~/dotfiles && stow nvim zsh tmux)."
echo "3. **Configurar o Timeshift:** Abra o Timeshift (procure no menu de aplicativos ou execute 'timeshift-launcher' no terminal) e configure os backups do sistema."
echo "4. **Abrir o Neovim:** Execute 'nvim' e use :Lazy ou o comando do seu gerenciador de plugins para instalar/atualizar plugins."
echo "5. **Abrir o Tmux:** Execute 'tmux' e use o prefixo + I (geralmente Ctrl+b + I) para instalar plugins do TPM, se configurado."
echo "6. **Configurar o mise:** Use 'mise use -g <linguagem>@latest' para instalar e gerenciar versões de linguagens (ex: 'mise use -g node@latest', 'mise use -g python@latest')."
echo "7. **Configurar o Minikube/Kubectl:** Siga a documentação para iniciar o Minikube ('minikube start') ou configurar o kubectl para conectar ao seu cluster."
echo "8. **Configurar o Hyprland:** Edite os arquivos em ~/.config/hypr/, ~/.config/waybar/, etc., conforme necessário."
echo "9. **Iniciar o Hyprland:** Use um Display Manager (como SDDM, GDM, Ly) ou inicie manualmente a partir do TTY (geralmente executando 'Hyprland')."
echo "10. **Verificar Agente Polkit:** Certifique-se de que '/usr/lib/polkit-kde-authentication-agent-1' (ou outro agente) está sendo iniciado com sua sessão Hyprland (ex: 'exec-once = /usr/lib/polkit-kde-authentication-agent-1' no hyprland.conf)."
echo "11. **Verificar Chave SSH:** Se necessário, adicione a chave pública SSH (~/.ssh/id_ed25519.pub) aos serviços que você usa (GitHub, GitLab, etc.)."
echo "12. **Explorar Novos Aplicativos:** Lembre-se que Ghostty (terminal), Timeshift (backup) e Zen Browser (navegador via Flatpak) foram instalados."
