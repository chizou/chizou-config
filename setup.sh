#!/bin/bash

download_files() {
    base_url='https://raw.githubusercontent.com/chizou/chizou-config/master'
    for filename in $(curl --silent ${base_url}/file_list); do
        wget ${base_url}/configs/${filename} -P ~/.config-downloads/
    done
}

dl_dir=~/.config-downloads
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
mkdir -p ~/.vim/{backups,swapfiles,autoload}
cp ${dl_dir}/vimrc ~/.vimrc
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -c ':PlugInstall | :q | :q'

# install nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.bashrc
nvm install node
npm install diff-so-fancy

# setup git
git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

# Setup bash
cat ${dl_dir}/bash >> ~/.bashrc
