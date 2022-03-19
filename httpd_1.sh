#!/bin/bash

sudo reflector --country 'United States' --latest 200 --protocol https --age 24 --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew
sudo pacman -Syuu --noconfirm
sudo pacman -S base base-devel --noconfirm
yes | sudo pacman -S git svn git-lfs jq tmux neovim zsh zsh-completions imagemagick libmagick wget man arch-wiki-lite --noconfirm
sudo pacman -S gcc xz ncurses glu mesa wxgtk2 libpng oniguruma libssh unixodbc binutils make fakeroot autoconf automake bison freetype2 gettext icu krb5 libedit libjpeg libpng libxml2 libzip pkg-config re2c zlib unzip openssl-1.0 ctags ncurses ack the_silver_searcher fontconfig libmagick6 --noconfirm
sudo curl -O https://blackarch.org/strap.sh
sudo sha1sum strap.sh
sudo chmod +x strap.sh
yes | sudo ./strap.sh --noconfirm
sudo rm -rf ~/strap.sh
yes | sudo pacman -Syuu --noconfirm 
yes | sudo pacman -S yay --noconfirm 
sudo runuser -l vagrant -c 'yes | yay -Syuu --devel --timeupdate --noconfirm' 
sudo runuser -l vagrant -c 'yes | yay -S devtools asdf-vm rcm heroku-cli bfg universal-ctags-git --noconfirm' 
yes | sudo pacman -S docker docker-compose --noconfirm
sudo runuser -l vagrant -c 'chsh -s $(which zsh)'
sudo runuser -l vagrant -c 'git clone git://github.com/thoughtbot/dotfiles.git ~/dotfiles'
