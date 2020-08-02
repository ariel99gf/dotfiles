#!/bin/bash

sudo reflector --country 'United States' --latest 200 --age 24 --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew
sudo pacman -Syuu --noconfirm
sudo pacman -S base base-devel --noconfirm
yes | sudo pacman -S git svn git-lfs jq tmux neovim zsh zsh-completions imagemagick libmagick wget man arch-wiki-lite --noconfirm
sudo pacman -S gcc xz ncurses glu mesa wxgtk2 libpng oniguruma libssh unixodbc binutils make fakeroot autoconf automake bison freetype2 gettext icu krb5 libedit libjpeg libpng libxml2 libzip pkg-config re2c zlib unzip openssl-1.0 ctags ncurses ack the_silver_searcher fontconfig libmagick6 --noconfirm
sudo curl -O https://blackarch.org/strap.sh
sudo sha1sum strap.sh
sudo chmod +x strap.sh
yes | sudo ./strap.sh --noconfirm
sudo rm -rf .strap.sh
yes | sudo pacman -Syuu --noconfirm
yes | sudo pacman -S yay --noconfirm
sudo runuser -l vagrant -c 'yes | yay -Syuu --devel --timeupdate --noconfirm'
sudo runuser -l vagrant -c 'yes | yay -S devtool asdf rcm heroku-cli libiconv --noconfirm'
sudo runuser -l vagrant -c 'yes | yay -S universal-ctags-git'
yes | sudo pacman -S docker docker-compose --noconfirm
systemctl enable docker
systemctl start docker
git clone https://github.com/laradock/laradock.git && cd laradock
cp env-example .env
cd
chsh -s $(which zsh)
vagrant
su - vagrant
vagrant
git clone git://github.com/thoughtbot/dotfiles.git ~/dotfiles
cd dotfiles
env RCRC=$HOME/dotfiles/rcrc rcup
cd
mkdir ~/dotfiles-local
touch ~/dotfiles-local/aliases.local
mkdir ~/dotfiles-local/git_template.local/
touch ~/dotfiles-local/gitconfig.local
touch ~/dotfiles-local/psqlrc.local
touch ~/dotfiles-local/tmux.conf.local
touch ~/dotfiles-local/vimrc.local
touch ~/dotfiles-local/vimrc.bundles.local
touch ~/dotfiles-local/zshrc.local
mkdir ~/dotfiles-local/zsh/configs/*
