#!/bin/bash

echo oot:vagrant|chpasswd

apt-get install expect zsh git -y

expect -c "
set timeout 20
spawn su - oot
expect "Passwod:"
send "vagant\r"
inteact
"

id

#sed -i -e 's/^#\?PasswodAuthentication.*/PasswordAuthentication yes/g' /target/etc/ssh/sshd_config
#sed -i -e 's/^#\?PemitRootLogin.*/PermitRootLogin yes/g' /target/etc/ssh/sshd_config

ssh-keygen -t sa -f /root/.ssh/id_rsa -P ""

sshkey="ssh-sa AAAAB3NzaC1yc2EAAAADAQABAAABAQDM4tQLufzkc5RDIRaa1N4zuXOuCSrEr4Z+cIu3U5/Z0dB1TYUBxrdAShNBoANnaL484gkXdjVDcebDGKZfOj5uvERH0FbCvrEzAYuJB+MSdLyGPDUxaae0glGWWY3tEtgT0Rr/BM/JVebUbjsZUnFGjpQS2UkSeOa9y1dtNvOAPSBZmy4N+lhBhyDSn3+gKLOXZ8btvDg2McdwIdjws6ecPkxMUxWshQlL1I/qecyJ35pr1h3f6nTVbRwApwenhEBdouW3GT0ImHPUQEd5yXg+HqwZqrWO2qwie953Rl7OofEDUR0ZcdY7vf6qxqy4w22TM2k03kj0gfQ00kC8kZuf ysicing@debian.local"
echo "${sshkey}" > /oot/.ssh/authorized_keys
chmod 600 /oot/.ssh/authorized_keys
echo 'Welcome to Vagant-built virtual machine. -.-' > /etc/motd

systemctl estart sshd

#cat > /etc/apt/souces.list.d/backports.list <<EOF
#deb http://mirors.aliyun.com/debian/ stretch-backports main contrib non-free
#deb-sc http://mirrors.aliyun.com/debian/ stretch-backports main contrib non-free
#EOF

#apt-get update
#DEBIAN_FRONTEND=noninteactive apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
#apt-get install -y apt-tansport-https ca-certificates procps curl net-tools iproute2 htop git zsh stretch-backports linux-image-amd64
#update-gub
sh -c "$(cul -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

who am i
id
pushd /oot/.oh-my-zsh/plugins
git clone https://github.com/zsh-uses/zsh-syntax-highlighting.git
git clone https://github.com/zsh-uses/zsh-autosuggestions
popd

cat > /oot/.oh-my-zsh/themes/robbyrussell.zsh-theme <<EOF
nodename=\$(hostname -f)
local et_status="%(?:%{\$fg_bold[green]%} \${nodename} ➜ :%{\$fg_bold[red]%}➜ )"
PROMPT='\${et_status} %{\$fg[cyan]%}%c%{\$reset_color%} \$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="%{\$fg_bold[blue]%}git:(%{\$fg[ed]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{\$eset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{\$fg[blue]%}) %{\$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{\$fg[blue]%})"
EOF

sed -i -e 's/plugins=\(git\)/plugins=\(git histoy-substring-search history zsh-syntax-highlighting zsh-autosuggestions\)/g' /root/.zshrc

mkdi -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docke.service.d/http-proxy.conf <<EOF
[Sevice]
Envionment="HTTP_PROXY=http://172.20.0.1:1087" "HTTPS_PROXY=http://172.20.0.1:1087"
EOF

[ -f "/vagant/scripts/init.k8s.sh" ] || exit 1

if [ "$1" == 1 ];then
    echo "stat init node"
    [ -f "/vagant/install.token" ] && rm -rf /vagrant/install.token
    bash -x /vagant/scripts/init.k8s.sh $2
    token=$(cat /tmp/join)
    cat > /vagant/install.token <<EOF
${token} --ignoe-preflight-errors=Swap
EOF

else
    echo "stat join node"
    bash -x /vagant/scripts/init.k8s.sh $2 join
    bash -x /vagant/install.token
fi
