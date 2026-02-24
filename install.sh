#!/bin/bash
# install.sh - Robust dotfiles bootstrap for DevPod/DevContainers

echo "🚀 Starting dotfiles configuration..."

# 1. Ensure ~/.local/bin is in the PATH for this current script session.
# This ensures the 'mise' command works in later steps even before a shell restart.
export PATH="$HOME/.local/bin:$PATH"

# 2. Update and install GNU Stow and curl (essential for linking and downloading).
if ! command -v stow &>/dev/null; then
  echo "📦 Installing GNU Stow and curl..."
  sudo apt-get update && sudo apt-get install -y stow curl
fi

# 3. Install the latest version of MISE directly from the source if not present.
if ! command -v mise &>/dev/null; then
  echo "🛠️  Installing Mise..."
  curl https://mise.run | sh
fi

# 4. Set up Tmux Plugin Manager (TPM).
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "🔌 Installing Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 5. PREPARE STOW (Critical Step)
# We remove the existing default .bash_aliases to allow stow to create symlinks.
# This prevents stow from skipping your files due to existing "real" files.
echo "🔗 Preparing symlinks..."
rm -f "$HOME/.bash_aliases"

# 6. Apply dotfiles using GNU Stow.
# This links your bash, tmux, and mise configurations to your $HOME directory.
cd "$(dirname "$0")"
echo "Applying stow for bash, tmux, and mise directories..."
stow --target="$HOME" --restow bash tmux mise

# 7. Setup LazyVim (Your personal Neovim preference).
if [ ! -d "$HOME/.config/nvim" ]; then
  echo "💤 Setting up LazyVim..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
fi

# 8. Install Global Tools via Mise.
# We explicitly point to your global config to ensure tools are installed
# regardless of the current project directory.
echo "📥 Installing personal global tools via Mise..."
mise trust "$HOME/.config/mise/config.toml"
mise install -y --config "$HOME/.config/mise/config.toml"

echo "✅ Dotfiles and global environment successfully configured!"
