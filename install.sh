#!/bin/bash

apt-get update

apt-get install -y apt-transport-https ca-certificates procps curl net-tools iproute2 htop git zsh

sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

who am i
id
cd /root/.oh-my-zsh/plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
git clone https://github.com/zsh-users/zsh-autosuggestions

echo $1 $2