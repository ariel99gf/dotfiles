#!/bin/bash
# install.sh - Robust dotfiles bootstrap for DevPod

echo "🚀 Starting dotfiles configuration..."

# 1. Ensure ~/.local/bin is in PATH for this script session
# This ensures step 6 works even if Mise was just installed
export PATH="$HOME/.local/bin:$PATH"

# 2. Update and install GNU Stow and curl
if ! command -v stow &>/dev/null; then
  echo "📦 Installing GNU Stow and curl..."
  sudo apt-get update && sudo apt-get install -y stow curl
fi

# 3. Install the latest version of MISE
if ! command -v mise &>/dev/null; then
  echo "🛠️  Installing Mise..."
  curl https://mise.run | sh
fi

# 4. Set up Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "🔌 Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 5. PREPARE STOW (Crucial!)
# We remove existing default files to allow stow to create symlinks without errors.
# The original .bashrc of the container is usually kept if you only link .bash_aliases.
# If your repo has a 'bash/.bashrc', uncomment the rm line below.
echo "🔗 Preparing symlinks..."
rm -f "$HOME/.bash_aliases"
# rm -f "$HOME/.bashrc" # Only uncomment if you have your own .bashrc in the repo

# 6. Apply dotfiles
cd "$(dirname "$0")"
echo "Applying stow for bash, tmux, and mise directories..."
stow --target="$HOME" --restow bash tmux mise

# 7. Setup LazyVim
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "💤 Setting up LazyVim..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

# 8. Install Tools via Mise
# We point to the linked config file to ensure Mise sees your global tools
echo "📥 Installing personal tools via Mise..."
mise trust "$HOME/.config/mise/config.toml"
mise install -y --config "$HOME/.config/mise/config.toml"

echo "✅ Dotfiles successfully configured!"
