#!/bin/bash

echo "Provisioning virtual machine..."


# Git
echo "Installing Git"
apt-get install git -y > /dev/null



# Nginx
echo "Installing Nginx"
apt-get install nginx -y > /dev/null


# PHP
echo "Updating PHP repository"
apt-get install python-software-properties build-essential -y > /dev/null
add-apt-repository ppa:ondrej/php5 -y > /dev/null
apt-get update > /dev/null

echo "Installing PHP"
apt-get install php5-common php5-dev php5-cli php5-fpm -y > /dev/null

echo "Installing PHP extensions"
apt-get install curl php5-curl php5-gd php5-mcrypt php5-mysql -y > /dev/null

# MySQL 
echo "Preparing MySQL"
apt-get install debconf-utils -y > /dev/null
debconf-set-selections <<< "mysql-server mysql-server/root_password password 1234"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 1234"

echo "Installing MySQL"
apt-get install mysql-server -y > /dev/null

# Nginx Configuration
echo "Configuring Nginx"
cp /var/www/provision/config/nginx_vhost /etc/nginx/sites-available/nginx_vhost > /dev/null
ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/

rm -rf /etc/nginx/sites-available/default

# Restart Nginx for the config to take effect
service nginx restart > /dev/null


# remove comment if you want to enable debugging
#set -x

if [ -e /etc/redhat-release ] ; then
  REDHAT_BASED=true
fi


TERRAFORM_VERSION="0.12.12"
PACKER_VERSION="1.2.4"
# create new ssh key
[[ ! -f /home/ubuntu/.ssh/mykey ]] \
&& mkdir -p /home/ubuntu/.ssh \
&& ssh-keygen -f /home/ubuntu/.ssh/mykey -N '' \
&& chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# install packages
if [ ${REDHAT_BASED} ] ; then
  yum -y update
  yum install -y docker ansible unzip wget
else 
  apt-get update
  apt-get -y install docker.io
fi
# add docker privileges
usermod -G docker ubuntu
# install pip
pip install -U pip && pip3 install -U pip

#if [[ $? == 127 ]]; then
#    wget -q https://bootstrap.pypa.io/get-pip.py
#    python get-pip.py
#    python3 get-pip.py
#fi

# install awscli and ebcli
#pip install -U awscli
#pip install awscli

#echo "*** Installing AWS CLI ***"
#sudo -H pip install --upgrade awscli
#sudo -H pip install --upgrade boto

echo "*** Install python3 ***"
apt-get update \
   && apt-get install -y python3-pip python3-dev \
   && cd /usr/local/bin \
   && ln -s /usr/bin/python3 python \
   && pip3 install --upgrade pip

echo "*** Install Python Modules ***"
pip3 install pymongo
pip3 install boto3
pip3 install botocore
pip3 install uuid
pip3 install --upgrade --user boto3


mkdir /db_backups/
#echo "*** Checking AWS CLI installation ***"
#aws --version

#terraform
T_VERSION=$(/usr/local/bin/terraform -v | head -1 | cut -d ' ' -f 2 | tail -c +2)
T_RETVAL=${PIPESTATUS[0]}

[[ $T_VERSION != $TERRAFORM_VERSION ]] || [[ $T_RETVAL != 0 ]] \
&& wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
&& unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
terraform version >> README.md

# packer
P_VERSION=$(/usr/local/bin/packer -v)
P_RETVAL=$?

[[ $P_VERSION != $PACKER_VERSION ]] || [[ $P_RETVAL != 1 ]] \
&& wget -q https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
&& unzip -o packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/local/bin \
&& rm packer_${PACKER_VERSION}_linux_amd64.zip

#get golang 1.11.1
curl -O https://storage.googleapis.com/golang/go1.11.1.linux-amd64.tar.gz
#unzip the archive 
tar -xvf go1.11.1.linux-amd64.tar.gz
#move the go lib to local folder
mv go /usr/local/
#delete the source file
rm  go1.11.1.linux-amd64.tar.gz
#only full path will work
#touch /home/vagrant/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin" >> /home/vagrant/.bashrc
echo "export GOPATH=/home/vagrant/workspace:$PATH" >> /home/vagrant/.bashrc
export GOPATH=/home/vagrant/workspace
mkdir -p "$GOPATH/bin" 


#https://docs.aws.amazon.com/cli/latest/userguide/install-linux.html#install-linux-pip
echo "*** install pip ***"

apt-get install python2.7
sudo curl -O https://bootstrap.pypa.io/get-pip.py
sudo python2.7 get-pip.py
sudo pip install awscli

#export PATH=~/.local/bin:$PATH
#source ~/.bashrc
pip --version

echo "*** Install the AWS CLI with pip ***"
pip install awscli --upgrade --user
aws --version

echo "*** Verify the latest version of the AWS CLI with pip ***"
pip list -o

echo "*** Ugrade the AWSCLI ***"
pip install --upgrade --user awscli
which aws
which python
which python3
ls -al /usr/local/bin/python

#https://itnext.io/kubernetes-hardening-d24bdf7adc25

echo "*** Installing kops ***"
curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops

#Docker
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

echo "*** Configuring locales ***"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

echo "*** Installing Docker ***"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y -qq update -o=Dpkg::Use-Pty=0
apt-get -y -qq install -o=Dpkg::Use-Pty=0 docker-ce
usermod -aG docker "$(logname)"

#cp /tmp/files/daemon.json /etc/docker

echo "*** Installing Docker Compose ***"
su -c "curl -sSL https://github.com/docker/compose/releases/download/1.24.0/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose"
chmod +x /usr/local/bin/docker-compose

echo "*** Checking Docker installation ***"
#docker-compose version
#docker info

echo "*** Installing kubectl ***"
apt-get -y -qq install -o=Dpkg::Use-Pty=0 bridge-utils
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl

echo "*** Checking kubectl installation ***"
kubectl version --client

#https://github.com/kubernetes/minikube/issues/4350
#https://kubernetes.io/docs/setup/learning-environment/minikube/#minikube-features
#https://medium.com/@nieldw/running-minikube-with-vm-driver-none-47de91eab84c

echo "*** Installing minikube ***"
curl -Lo minikube https://github.com/kubernetes/minikube/releases/download/v1.1.0/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/

echo "*** Checking minicube installation ***"
minikube version

# https://www.infoworld.com/article/3230547/awless-tutorial-try-a-smarter-cli-for-aws.html
# https://github.com/wallix/awless

echo "*** Install ARK ***"
wget https://github.com/heptio/ark/releases/download/v0.9.3/ark-v0.9.3-linux-amd64.tar.gz
tar -xvf ark-v0.9.3-linux-amd64.tar.gz
mv ark /usr/bin/ark

echo "*** Install awless ***"
curl https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash
sudo mv awless /usr/local/bin/
echo 'source <(awless completion bash)' >> ~/.bashrc

echo "*** Multi pod and container log tailing for Kubernetes ***"
mkdir -p $GOPATH/src/github.com/wercker
cd $GOPATH/src/github.com/wercker
git clone https://github.com/wercker/stern.git && cd stern
govendor sync
go install

echo "*** Install postgreSQL ***"
#apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev libcurl4-openssl-dev python-software-properties libpq-dev postgresql postgresql-contrib
#apt-get -y install postgresql-client-common

echo "*** Add PostgreSQL 11 APT repository ***"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main"
apt-get -y install postgresql-11
sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/11/main/postgresql.conf
systemctl restart postgresql
apt-get -y install postgresql-client

#https://medium.com/@gajus/the-missing-ci-cd-kubernetes-component-helm-package-manager-1fe002aac680

echo "*** Installing helm ***"
curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.14.0-linux-amd64.tar.gz
tar -xvzf helm-v2.14.0-linux-amd64.tar.gz
cp ./linux-amd64/helm /usr/local/bin
cp ./linux-amd64/tiller /usr/local/bin
rm -rf ./linux-amd64

echo "*** Checking helm installation ***"
helm version --client

echo "*** Setup MongoDB ***"
# Install MongoDB
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

# Start and enable the Mongo service so that it automatically starts every time you start the machine
systemctl start mongod.service
systemctl enable mongod.service

mongo --eval 'db.runCommand({ connectionStatus: 1 })'

echo "*** Installing Ansible ***"
apt-add-repository -y ppa:ansible/ansible
apt-get -y -qq update -o=Dpkg::Use-Pty=0 
apt-get -y -qq install -o=Dpkg::Use-Pty=0 ansible
#sudo -H pip uninstall docker-py; sudo -H pip uninstall docker; sudo -H pip install docker
sudo -H pip install lxml

#echo "*** Configuring Ansible to run on localhost ***"
#echo 'localhost ansible_connection=local' > /etc/ansible/hosts
#cp /tmp/files/ansible.cfg /etc/ansible
 
echo "*** Checking Ansible installation ***"
python --version
ansible --version 
#&& chown -R "$(logname):$(logname)" "/home/$(logname)/.ansible"

#Install base tools
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

echo "*** Cleaning ***"
rm /var/cache/debconf/*.dat
apt-get -y -qq clean

echo "*** Preparing ***"
apt-get -y -qq install -o=Dpkg::Use-Pty=0 --reinstall debconf
dpkg-reconfigure debconf

#https://hostpresto.com/community/tutorials/how-to-use-screen-on-linux/

echo "*** Updating system ***"
apt-get -y install ntp unzip screen
echo "ip_adress" >> /etc/ntp
sed -i 's/pool /#pool /g' /etc/ntp.conf
systemctl restart ntp.service

UCF_FORCE_CONFFNEW=true
export UCF_FORCE_CONFFNEW
# sed -i 's/console=hvc0/console=ttyS0/' /boot/grub/menu.lst
sed -i 's/LABEL=UEFI.*//' /etc/fstab
apt-get -y -qq update -o=Dpkg::Use-Pty=0
apt-get -y -qq upgrade -o=Dpkg::Use-Pty=0

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
apt-get -y -qq install -o=Dpkg::Use-Pty=0 linux-headers-$(uname -r)
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

echo "*** Configuring permissions ***"
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=sudo' /etc/sudoers
sed -i -e 's/%sudo  ALL=(ALL:ALL) ALL/%sudo  ALL=NOPASSWD:ALL/g' /etc/sudoers

echo "*** Configuring networks ***"
# Disable DNS reverse lookup
echo "UseDNS no" >> /etc/ssh/sshd_config

DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND

echo "*** Installing tools ***"

sudo -H apt-get -qq -y install -o=Dpkg::Use-Pty=0 zip unzip wget curl mc links tree tofrodos cifs-utils smbclient
sudo -H apt-get -qq -y install -o=Dpkg::Use-Pty=0 apt-transport-https ca-certificates software-properties-common

sudo -H apt-get -y -qq install -o=Dpkg::Use-Pty=0 httpie

wget --quiet --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/bin/jq
chmod a+x /usr/bin/jq

echo "*** Installing GO ***"


echo "*** Installing vault ***"

VAULT_VERSION="1.2.3"
curl -sO https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

unzip vault_${VAULT_VERSION}_linux_amd64.zip
mv vault /usr/local/bin/
vault --version

#Enable command autocompletion.
vault -autocomplete-install
complete -C /usr/local/bin/vault vault

#Configure Vault systemd service
sudo mkdir /etc/vault
sudo mkdir -p /var/lib/vault/data

#create user named vault.
sudo useradd --system --home /etc/vault --shell /bin/false vault
sudo chown -R vault:vault /etc/vault /var/lib/vault/

#Create a Vault service file

cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill --signal HUP 
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

#Create Vault /etc/vault/config.hcl file.

touch /etc/vault/config.hcl
cat <<EOF | sudo tee /etc/vault/config.hcl
disable_cache = true
disable_mlock = true
ui = true
listener "tcp" {
   address          = "0.0.0.0:8200"
   tls_disable      = 1
}
storage "file" {
   path  = "/var/lib/vault/data"
 }
api_addr         = "http://0.0.0.0:8200"
max_lease_ttl         = "10h"
default_lease_ttl    = "10h"
cluster_name         = "vault"
raw_storage_endpoint     = true
disable_sealwrap     = true
disable_printable_check = true
EOF

echo "*** Consul Storage backend, but first you’ll need to install Consul ***"

export VER="1.5.1"
wget https://releases.hashicorp.com/consul/${VER}/consul_${VER}_linux_amd64.zip
unzip consul_${VER}_linux_amd64.zip
sudo mv consul /usr/local/bin/
consul --help
consul -v

echo "*** Bootstrap and start Consul Cluster ***"

#https://computingforgeeks.com/install-and-configure-vault-server-linux/
#https://computingforgeeks.com/how-to-install-consul-cluster-18-04-lts/

echo "*** restoring failed kops cluster ***"
#https://hindenes.com/2019-08-09-Kops-Restore/

#NOTE if using a different etcd-manager version, adjust the download link accordingly. It should matche the version of the /etcd-manager in the same container
apt-get update && apt-get install -y wget
wget https://github.com/kopeio/etcd-manager/releases/download/3.0.20190801/etcd-manager-ctl-linux-amd64
mv etcd-manager-ctl-linux-amd64 etcd-manager-ctl
chmod +x etcd-manager-ctl
mv etcd-manager-ctl /usr/local/bin/

echo "*** Cleaning up APT caches ***"
apt-get -y -qq autoremove -o=Dpkg::Use-Pty=0
apt-get -y -qq clean -o=Dpkg::Use-Pty=0

echo "*** Cleaning up guest additions ***"
rm -rf VBoxGuestAdditions_*.iso VBoxGuestAdditions_*.iso.?

echo "*** Cleaning up DHCP leases ***"
rm -rf /var/lib/dhcp/*

echo "*** Cleaning up udev rules ***"
# rm -rf /etc/udev/rules.d/70-persistent-net.rules
# rm -rf /dev/.udev/
# rm -rf /lib/udev/rules.d/75-persistent-net-generator.rules

sudo apt-get install ntp
echo "ip_adress" >> /etc/ntp
sed -i 's/pool /#pool /g' /etc/ntp.conf
sudo systemctl restart ntp.service
sudo service ntp start
sudo service ntp service

echo "*** Cleaning /tmp ***"
rm -rf /tmp/*
rm -rf /var/tmp/*

# clean up
if [ ! ${REDHAT_BASED} ] ; then
  apt-get clean
fi


echo "*** Installing phpMyAdmin ***"

#https://github.com/spiritix/vagrant-php7

echo "-- Prepare configuration for MySQL --"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

echo "-- Install tools and helpers --"
sudo apt-get install -y --force-yes python-software-properties vim htop curl git npm build-essential libssl-dev

echo "-- Install PPA's --"
sudo add-apt-repository ppa:ondrej/php
sudo add-apt-repository ppa:chris-lea/redis-server
Update

echo "-- Install NodeJS --"
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -

echo "-- Install packages --"
sudo apt-get install -y --force-yes apache2 mysql-server-5.7 git-core nodejs rabbitmq-server redis-server
sudo apt-get install -y --force-yes php7.1-common php7.1-dev php7.1-json php7.1-opcache php7.1-cli libapache2-mod-php7.1
sudo apt-get install -y --force-yes php7.1 php7.1-mysql php7.1-fpm php7.1-curl php7.1-gd php7.1-mcrypt php7.1-mbstring
sudo apt-get install -y --force-yes php7.1-bcmath php7.1-zip
Update

echo "-- Configure PHP &Apache --"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/apache2/php.ini
sudo a2enmod rewrite

echo "-- Creating virtual hosts --"
sudo ln -fs /vagrant/public/ /var/www/app
cat << EOF | sudo tee -a /etc/apache2/sites-available/default.conf
<Directory "/var/www/">
    AllowOverride All
</Directory>
<VirtualHost *:80>
    DocumentRoot /var/www/app
    ServerName app.local
</VirtualHost>
<VirtualHost *:80>
    DocumentRoot /var/www/phpmyadmin
    ServerName phpmyadmin.local
</VirtualHost>
EOF
sudo a2ensite default.conf

echo "-- Restart Apache --"
sudo /etc/init.d/apache2 restart

echo "-- Install Composer --"
curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

echo "-- Install phpMyAdmin --"
wget -k https://files.phpmyadmin.net/phpMyAdmin/4.8.0.1/phpMyAdmin-4.8.0.1-english.tar.gz
sudo tar -xzvf phpMyAdmin-4.8.0.1-english.tar.gz -C /var/www/
sudo rm phpMyAdmin-4.8.0.1-english.tar.gz
sudo mv /var/www/phpMyAdmin-4.8.0.1-english/ /var/www/phpmyadmin

echo "-- Setup databases --"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -proot -e "CREATE DATABASE my_database";

#Small Tools & Utilities
sudo apt install whois \
  curl \
  dconf-cli \
  exiftool \
  htop \
  ipcalc \
  jq \
  logtail \
  tmux \
  xdotool \ 
&& true

#Browser

# First let's install some of those non-free codecs so I can watch videos online:
sudo apt install ubuntu-restricted-extras

# Then let's take the very latest Firefox from Mozilla
cd /tmp \
  && curl -sSLo ./firefox.tar.bz2 'https://download.mozilla.org/?product=firefox-latest&os=linux64' \
  && sudo tar xjf ./firefox.tar.bz2 -C /opt/ \
  && sudo ln -nfs /opt/firefox/firefox /usr/lib/firefox/firefox \
  && firefox \
  && cd -

#Email

sudo apt install thunderbird

#If you want to allow incoming SSH connections:

sudo apt install openssh-server

#basic PHP & MySQL CLI
sudo apt install php-cli php-mbstring php-mysql mysql-client
