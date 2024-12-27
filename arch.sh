#!/bin/bash

yes | sudo pacman-key --init
yes | sudo pacman-key --populate
yes | sudo pacman -Syy archlinux-keyring
yes | sudo pacman -Syuu --noconfirm
yes | sudo pacman -S reflector --noconfirm
sudo reflector --country 'United States' --latest 200 --protocol https --age 24 --sort rate --save /etc/pacman.d/mirrorlist
rm -f /etc/pacman.d/mirrorlist.pacnew
yes | sudo pacman -S base base-devel --noconfirm
yes | sudo pacman -S git svn git-lfs jq tmux neovim zsh zsh-completions imagemagick libmagick wget man arch-wiki-lite jdk-openjdk kotlin rust npm yarn ruby ansible terraform --noconfirm
yes | sudo pacman -S gcc xz ncurses glu mesa libpng oniguruma libssh unixodbc binutils make fakeroot autoconf zip automake bison freetype2 gettext icu krb5 libedit libjpeg libpng libxml2 libzip pkg-config re2c zlib unzip openssl ctags ncurses ack the_silver_searcher fontconfig exa tldr dust fd tokei procs hyperfine skim sd bottom bat fzf --needed
curl -O https://blackarch.org/strap.sh
echo 5ea40d49ecd14c2e024deecf90605426db97ea0c strap.sh | sha1sum -c
chmod +x strap.sh
sudo ./strap.sh
sudo rm -rf ~/strap.sh
yes | sudo pacman -Syuu --noconfirm
cd /opt && sudo git clone https://aur.archlinux.org/yay-git.git && sudo chown -R "$USER:$USER" ./yay-git && cd yay-git && makepkg -si && yay -Syu --devel --timeupdate
yes | yay -Syuu --devel --timeupdate --noconfirm
yes | yay -S devtools asdf-vm rcm bfg universal-ctags-git zsh-theme-powerlevel10k-git --noconfirm
curl -s "https://get.sdkman.io" | bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
curl https://mise.run | sh
curl -L git.io/antigen >~/.antigen.zsh
source "$HOME/.sdkman/bin/sdkman-init.sh"
chsh -s "$(which zsh)"
sudo usermod -aG docker "${USER}"
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
