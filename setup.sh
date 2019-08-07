#!/bin/bash

download_files() {
    base_url='https://raw.githubusercontent.com/chizou/chizou-configs/master'
    for filename in $(curl --silent ${base_url}/file_list); do
        wget ${base_url}/configs/${filename} -o ~/.config-downloads/
    done
}

dl_dir='~/.config-downloads'
mkdir ${dl_dir}
download_files

# Setup SSH
mkdir ~/.ssh
cp ${dl_dir}/authorized_keys ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 700 /.ssh

# Setup screen
cp ${dl_dir}/screenrc ~/.screenrc

# Setup vim
mkdir -p ~/.vim/{backups,swapfiles}
cp ${dl_dir}/vimrc ~/.vimrc
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Setup bash
cat ${dl_dir}/bash >> ~/.bashrc
