#!/bin/bash
# install.sh - Your environment's "Bootloader"

# 1. Install system essentials
echo "📦 Installing system essentials (stow, curl, git)..."
sudo apt-get update && sudo apt-get install -y stow curl git

# 2. Install Mise (The tool manager)
if ! command -v mise &>/dev/null; then
  echo "🛠️ Installing Mise..."
  curl https://mise.run | sh
fi
# Ensure Mise is in the PATH for this script session
export PATH="$HOME/.local/bin:$PATH"

# 3. Apply symlinks (Stow)
echo "🚀 Applying symlinks via Stow..."
cd "$(dirname "$0")"
stow --target="$HOME" --restow bash tmux mise

# 4. Install everything in config.toml (eza, bat, nvim...)
echo "📥 Installing global tools via Mise..."
mise trust
mise install -y

echo "✅ Environment successfully bootstrapped!"
