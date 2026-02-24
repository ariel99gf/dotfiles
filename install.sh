#!/bin/bash
# install.sh - Simple & Robust Bootstrapper

echo "🚀 Starting Personal Environment Setup..."

# 1. Force ~/.local/bin into PATH for this script execution
export PATH="$HOME/.local/bin:$PATH"

# 2. Install essentials
sudo apt-get update && sudo apt-get install -y stow curl git

# 3. Ensure Mise is installed
if ! command -v mise &>/dev/null; then
  curl https://mise.run | sh
fi

# 4. Apply Symlinks
# Since we renamed to .bash_aliases, Stow will succeed without conflicts
cd "$(dirname "$0")"
stow --target="$HOME" --restow bash tmux mise

# 5. Install Personal Tools using your dotfiles config
echo "📥 Installing tools (eza, nvim, bat...) from global config..."
mise trust "$HOME/.config/mise/config.toml"
mise install -y --config "$HOME/.config/mise/config.toml"

echo "✅ Success! Please run 'source ~/.bashrc' if aliases aren't active yet."
