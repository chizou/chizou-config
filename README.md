# Install
`ansible-playbook local.yml`

# Additional Steps

Run these additional steps after install


1. Follow instructions here: https://help.github.com/en/github/authenticating-to-github/generating-a-new-gpg-key
2. Set the GPG key in git  
    a. `gpg --import <gpg-key-file>`  
    or  
    b. `git config --global user.signingkey $(gpg --list-secret-keys --keyid-format LONG | grep -E '^sec' | sed -r  "s/.*\/([A-F0-9]+).*/\\1/")`
3. vim -c ':PlugInstall | :q | :q'
