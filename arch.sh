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
# Verifica se o Yay já está instalado
if ! command -v yay &> /dev/null; then
    echo "--> Yay não encontrado. Instalando a partir do AUR..."
    # Define um diretório temporário para build
    BUILD_DIR=$(mktemp -d)
    echo "--> Usando diretório temporário para build: $BUILD_DIR"

    # Garante que git e base-devel estão instalados (já devem estar pela seção anterior)
    yes | sudo pacman -S --noconfirm --needed git base-devel

    # Clona o repositório do yay-git no diretório temporário
    git clone https://aur.archlinux.org/yay-git.git "$BUILD_DIR/yay-git"

    # Entra no diretório clonado
    cd "$BUILD_DIR/yay-git"

    # Constrói e instala o pacote
    # makepkg -si instalará as dependências, construirá o pacote e o instalará usando pacman
    # --noconfirm responde 'sim' para as perguntas do makepkg e do pacman (instalação)
    makepkg -si --noconfirm

    # Volta para o diretório home
    cd "$HOME"

    # Limpa o diretório temporário (opcional, mas recomendado)
    echo "--> Limpando diretório temporário de build..."
    rm -rf "$BUILD_DIR"

    echo "--> Yay instalado com sucesso."
else
    echo "--> Yay já está instalado."
fi


# --- Instalação de Pacotes do AUR via Yay ---
echo "--> Instalando pacotes do AUR via Yay..."
# Agora podemos usar o yay que acabamos de instalar (ou que já existia)
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

# --- Geração e Configuração da Chave SSH para GitHub ---
echo "--> Configurando chave SSH para GitHub..."
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_KEY_PUB_PATH="$SSH_KEY_PATH.pub"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "--> Gerando nova chave SSH ED25519..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Gera a chave sem passphrase
    ssh-keygen -o -a 100 -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "$(whoami)@$(hostname)-$(date -I)"
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "$SSH_KEY_PUB_PATH"
    echo "--> Nova chave SSH gerada em '$SSH_KEY_PATH'."
else
    echo "--> Chave SSH ED25519 já existe em '$SSH_KEY_PATH'."
fi

echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!! AÇÃO NECESSÁRIA: Adicione a seguinte chave SSH pública às suas configurações do GitHub !!"
echo "!! Vá para GitHub -> Settings -> SSH and GPG keys -> New SSH key                  !!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
cat "$SSH_KEY_PUB_PATH"
echo ""
read -r -p "Pressione ENTER após adicionar a chave SSH ao GitHub e testar a conexão (ssh -T git@github.com)..."
echo ""


# --- Clonar e Configurar Dotfiles com Stow ---
echo "--> Clonando repositório de dotfiles de ariel99gf..."
DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="git@github.com:ariel99gf/dotfiles.git"
SKIP_STOW=false # Inicializa a variável

# Verifica se o diretório já existe
if [ -d "$DOTFILES_DIR" ]; then
    echo "--> Diretório '$DOTFILES_DIR' já existe. Verificando se é um repositório git..."
    if [ -d "$DOTFILES_DIR/.git" ]; then
        echo "--> É um repositório git. Tentando atualizar (git pull)..."
        cd "$DOTFILES_DIR"
        if git pull; then
            echo "--> Repositório atualizado com sucesso."
        else
            echo "--> AVISO: Falha ao atualizar o repositório. Pode haver alterações locais não commitadas ou problemas de conexão."
        fi
        cd "$HOME" # Volta para o diretório home
    else
        echo "--> '$DOTFILES_DIR' existe mas não é um repositório git. Renomeando para '$DOTFILES_DIR.bak' e clonando novamente."
        mv "$DOTFILES_DIR" "$DOTFILES_DIR.bak_$(date +%Y%m%d%H%M%S)"
        # Clona o repositório
        if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
            echo "--> Repositório clonado com sucesso em '$DOTFILES_DIR'."
        else
            echo "--> ERRO: Falha ao clonar o repositório '$DOTFILES_REPO'."
            echo "--> Verifique se a chave SSH foi adicionada corretamente ao GitHub e se a URL do repositório está correta."
            SKIP_STOW=true
        fi
    fi
else
    # Clona o repositório
    echo "--> Clonando o repositório '$DOTFILES_REPO'..."
    if git clone "$DOTFILES_REPO" "$DOTFILES_DIR"; then
        echo "--> Repositório clonado com sucesso em '$DOTFILES_DIR'."
    else
        echo "--> ERRO: Falha ao clonar o repositório '$DOTFILES_REPO'."
        echo "--> Verifique se a chave SSH foi adicionada corretamente ao GitHub e se a URL do repositório está correta."
        SKIP_STOW=true
    fi
fi

if [ "$SKIP_STOW" = false ] && [ -d "$DOTFILES_DIR" ]; then
    echo "--> Configurando dotfiles com Stow..."
    cd "$DOTFILES_DIR"

    # Lista de diretórios a serem gerenciados pelo stow (exceto nvim)
    # Baseado na imagem: gitconf, tmux, zsh
    STOW_DIRS=(gitconf tmux zsh)

    echo "--> Criando links para: ${STOW_DIRS[*]}"
    # -v (verbose), -S (stow), -t ~ (target é o diretório home)
    # Adicionado --adopt para tentar resolver conflitos movendo arquivos existentes para o diretório do stow
    if stow --adopt -vSt ~ "${STOW_DIRS[@]}"; then
        echo "--> Links simbólicos (stow) criados/adotados com sucesso para ${STOW_DIRS[*]}. Verifique se houve adoções e faça commit no seu repo de dotfiles se necessário."
    else
        echo "--> AVISO: Ocorreram erros ao executar o stow para ${STOW_DIRS[*]}. Verifique as mensagens acima."
        echo "--> Pode ser necessário remover arquivos conflitantes manualmente em '$HOME' antes de executar o stow novamente."
    fi

    # Tratar nvim separadamente devido à estrutura nvim/.config/nvim no repo
    NVIM_SOURCE_PATH="$DOTFILES_DIR/nvim/.config/nvim"
    NVIM_TARGET_PATH="$HOME/.config/nvim"
    echo "--> Tratando configuração do nvim separadamente..."
    if [ -d "$NVIM_SOURCE_PATH" ]; then
        # Cria o diretório ~/.config se não existir
        mkdir -p "$HOME/.config"

        # Verifica se o destino já existe e é um link simbólico
        if [ -L "$NVIM_TARGET_PATH" ]; then
            echo "--> Link simbólico para nvim já existe em '$NVIM_TARGET_PATH'. Pulando."
        # Verifica se o destino já existe e é um diretório (não um link)
        elif [ -d "$NVIM_TARGET_PATH" ]; then
            echo "--> AVISO: Diretório '$NVIM_TARGET_PATH' já existe e não é um link. Fazendo backup para '$NVIM_TARGET_PATH.bak_$(date +%Y%m%d%H%M%S)'."
            mv "$NVIM_TARGET_PATH" "$NVIM_TARGET_PATH.bak_$(date +%Y%m%d%H%M%S)"
            # Cria o link simbólico
            if ln -sfn "$NVIM_SOURCE_PATH" "$NVIM_TARGET_PATH"; then
                 echo "--> Link simbólico para nvim criado: $NVIM_TARGET_PATH -> $NVIM_SOURCE_PATH"
            else
                 echo "--> ERRO: Falha ao criar link simbólico para nvim após backup."
            fi
        # Se não existe, cria o link
        else
            if ln -sfn "$NVIM_SOURCE_PATH" "$NVIM_TARGET_PATH"; then
                echo "--> Link simbólico para nvim criado: $NVIM_TARGET_PATH -> $NVIM_SOURCE_PATH"
            else
                echo "--> ERRO: Falha ao criar link simbólico para nvim."
            fi
        fi
    else
        echo "--> AVISO: Diretório de origem do nvim não encontrado em '$NVIM_SOURCE_PATH'. Pulando link do nvim."
    fi

    cd "$HOME" # Volta para o diretório home
else
    echo "--> Pulando configuração com Stow devido a erro no clone ou diretório não encontrado."
fi

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

# --- Mensagens Finais e Próximos Passos ---
# A seção de geração de chave SSH foi movida para antes do clone dos dotfiles.
echo ""
echo "### Configuração Concluída! ###"
echo ""
echo "Próximos passos recomendados:"
echo "1. **Reiniciar o sistema** ou fazer **logout e login** para que todas as alterações tenham efeito (especialmente a adição ao grupo 'docker' e a mudança de shell para Zsh)."
echo "2. **Verificar Dotfiles:** Confirme se os links simbólicos foram criados corretamente em seu diretório home (para gitconf, tmux, zsh) e em ~/.config (para nvim)."
echo "3. **Configurar o Timeshift:** Abra o Timeshift (procure no menu de aplicativos ou execute 'timeshift-launcher' no terminal) e configure os backups do sistema."
echo "4. **Abrir o Neovim:** Execute 'nvim'. Se a configuração foi linkada corretamente, ele deve carregar suas configurações. Use :Lazy (ou o comando do seu gerenciador) para instalar plugins."
echo "5. **Abrir o Tmux:** Execute 'tmux'. Se a configuração foi linkada, ele deve carregar suas configurações. Use o prefixo + I (geralmente Ctrl+b + I) para instalar plugins do TPM, se configurado."
echo "6. **Configurar o mise:** Use 'mise use -g <linguagem>@latest' para instalar e gerenciar versões de linguagens (ex: 'mise use -g node@latest', 'mise use -g python@latest')."
echo "7. **Configurar o Minikube/Kubectl:** Siga a documentação para iniciar o Minikube ('minikube start') ou configurar o kubectl para conectar ao seu cluster."
echo "8. **Configurar o Hyprland:** Edite os arquivos em ~/.config/hypr/, ~/.config/waybar/, etc., conforme necessário."
echo "9. **Iniciar o Hyprland:** Use um Display Manager (como SDDM, GDM, Ly) ou inicie manualmente a partir do TTY (geralmente executando 'Hyprland')."
echo "10. **Verificar Agente Polkit:** Certifique-se de que '/usr/lib/polkit-kde-authentication-agent-1' (ou outro agente) está sendo iniciado com sua sessão Hyprland (ex: 'exec-once = /usr/lib/polkit-kde-authentication-agent-1' no hyprland.conf)."
echo "11. **Explorar Novos Aplicativos:** Lembre-se que Ghostty (terminal), Timeshift (backup) e Zen Browser (navegador via Flatpak) foram instalados."

