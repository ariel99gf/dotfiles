# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "archlinux/archlinux"
  config.disksize.size = '50GB'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"
  # config.vm.network "forwarded_port", guest: 5432, host: 54322, host_ip: "127.0.0.1"
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.0.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  # vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
    config.vm.provision "shell", inline: <<-SHELL
    yes | sudo pacman -Syuu --noconfirm
    yes | sudo pacman -S base base-devel --noconfirm
    yes | sudo pacman -S --needed base-devel --noconfirm
    yes | sudo pacman -S jq git tmux neovim zsh zsh-completions imagemagick libmagick wget man --noconfirm
    yes | sudo pacman -S gcc xz --noconfirm
    yes | sudo pacman -S ncurses --noconfirm
    yes | sudo pacman -S glu mesa wxgtk2 libpng oniguruma --noconfirm
    yes | sudo pacman -S libssh --noconfirm
    yes | sudo pacman -S unixodbc --noconfirm
    yes | sudo pacman -S binutils make gcc fakeroot --noconfirm
    yes | sudo pacman -S autoconf automake bison freetype2 gettext icu krb5 libedit libjpeg libpng libxml2 libzip pkg-config re2c zlib unzip --noconfirm
    yes | sudo pacman -S openssl-1.0 ctags ncurses ack the_silver_searcher fontconfig libmagick6 --noconfirm
    yes | sudo pacman -S nodejs php jdk-openjdk python erlang elixir go kotlin lua gradle julia  ruby r rust --noconfirm
    git config --global user.name "ariel99gf"
    git config --global user.email "ariel99gf@gmail.com"
    git config --global core.editor nvim
    sudo curl -sLf https://spacevim.org/install.sh | bash
    sudo runuser -l vagrant -c 'curl -sLf https://spacevim.org/install.sh | bash'
    sudo curl -O https://blackarch.org/strap.sh
    sudo sha1sum strap.sh
    sudo chmod +x strap.sh
    yes | sudo ./strap.sh --noconfirm
    yes | sudo pacman -Syuu --noconfirm
    yes | sudo pacman -S yay --noconfirm
    sudo runuser -l vagrant -c 'yes | yay -Syuu --devel --timeupdate --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S libiconv --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S heroku-cli --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S universal-ctags-git --noconfirm'
    sudo runuser -l vagrant -c 'yes | pacman -S devtools --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S neovim-plug  --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S vim-plug  --noconfirm'
    sudo runuser -l vagrant -c 'yes | yay -S antigen-git --noconfirm'
    echo -e '\n. source /usr/share/zsh/share/antigen.zsh' >> ~/.zshrc
  # yes | sudo pacman -S docker docker-compose ansible --noconfirm
  # systemctl enable docker
  # systemctl start docker
  # curl -L https://github.com/laravel/laravel/archive/v7.0.0.tar.gz | tar xz
  # git clone https://github.com/laradock/laradock.git && cd laradock
  # cp env-example .env
  # cd
  # mv laravel-7.0.0 my-project
  # sudo docker pull postgres
  # sudo docker pull mariadb
  # sudo docker pull memcached
  # sudo docker pull mongo
  # git clone https://github.com/ariel99gf/dotfiles.git
  # source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
    SHELL
end
