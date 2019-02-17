#!/bin/bash

echo root:vagrant|chpasswd

apt-get install expect zsh git -y

expect -c "
set timeout 20
spawn su - root
expect "Password:"
send "vagrant\r"
interact
"

id

#sed -i -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
#sed -i -e 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config

ssh-keygen -t rsa -f /root/.ssh/id_rsa -P ""

sshkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDM4tQLufzkc5RDIRaa1N4zuXOuCSrEr4Z+cIu3U5/Z0dB1TYUBxrdAShNBoANnaL484gkXdjVDcebDGKZfOj5uvERH0FbCvrEzAYuJB+MSdLyGPDUxaae0glGWWY3tEtgT0Rr/BM/JVebUbjsZUnFGjpQS2UkSeOa9y1dtNvOAPSBZmy4N+lhBhyDSn3+gKLOXZ8btvDg2McdwIdjws6ecPkxMUxWshQlL1I/qecyJ35pr1h3f6nTVbRwApwenhEBdouW3GT0ImHPUQEd5yXg+HqwZqrWO2qwie953Rl7OofEDUR0ZcdY7vf6qxqy4w22TM2k03kj0gfQ00kC8kZuf ysicing@debian.local"
echo "${sshkey}" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo 'Welcome to Vagrant-built virtual machine. -.-' > /etc/motd

systemctl restart sshd

#cat > /etc/apt/sources.list.d/backports.list <<EOF
#deb http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free
#deb-src http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free
#EOF

#apt-get update
#DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
#apt-get install -y apt-transport-https ca-certificates procps curl net-tools iproute2 htop git zsh stretch-backports linux-image-amd64
#update-grub
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

who am i
id
pushd /root/.oh-my-zsh/plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
git clone https://github.com/zsh-users/zsh-autosuggestions
popd

cat > /root/.oh-my-zsh/themes/robbyrussell.zsh-theme <<EOF
nodename=\$(hostname -f)
local ret_status="%(?:%{\$fg_bold[green]%} \${nodename} ➜ :%{\$fg_bold[red]%}➜ )"
PROMPT='\${ret_status} %{\$fg[cyan]%}%c%{\$reset_color%} \$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="%{\$fg_bold[blue]%}git:(%{\$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{\$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{\$fg[blue]%}) %{\$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{\$fg[blue]%})"
EOF

sed -i -e 's/plugins=\(git\)/plugins=\(git history-substring-search history zsh-syntax-highlighting zsh-autosuggestions\)/g' /root/.zshrc

mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=http://172.20.0.1:1087" "HTTPS_PROXY=http://172.20.0.1:1087"
EOF

[ -f "/vagrant/scripts/init.k8s.sh" ] || exit 1

if [ "$1" == 1 ];then
    echo "start init node"
    [ -f "/vagrant/install.token" ] && rm -rf /vagrant/install.token
    bash -x /vagrant/scripts/init.k8s.sh $2
    token=$(cat /tmp/join)
    cat > /vagrant/install.token <<EOF
${token} --ignore-preflight-errors=Swap
EOF

else
    echo "start join node"
    bash -x /vagrant/scripts/init.k8s.sh $2 join
    bash -x /vagrant/install.token
fi
