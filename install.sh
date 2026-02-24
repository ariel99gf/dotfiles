#!/bin/bash
# install.sh - Installs dotfiles inside DevPod/DevContainers

echo "Configuring dotfiles in DevPod..."

# 1. Update and install GNU Stow and curl (assuming an Ubuntu/Debian base container)
if ! command -v stow &>/dev/null; then
  echo "Installing GNU Stow and curl..."
  sudo apt-get update && sudo apt-get install -y stow curl
fi

# 2. Set up Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 3. Install the latest version of MISE directly from the source (if not present)
if ! command -v mise &>/dev/null; then
  echo "Installing the latest version of Mise..."
  curl https://mise.run | sh
  # Add mise to the PATH temporarily so this script can run 'mise install' later
  export PATH="$HOME/.local/bin:$PATH"
fi

# 4. Apply dotfiles (bash, tmux, and the global mise configuration)
echo "Applying stow for bash, tmux, and mise directories..."
cd "$(dirname "$0")"
stow --target="$HOME" --restow bash tmux mise

# 5. Install all global tools (eza, nvim, zoxide, fzf, etc.)
echo "Installing global tools via Mise..."
mise install -y

echo "Dotfiles successfully configured!"
