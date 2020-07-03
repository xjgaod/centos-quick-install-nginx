#!/bin/bash

function nginx_install() {

nginx=$1
sdnc=$2
sms=$3
nginxremote=root@$1
 
 genSshKeys;
 pushKeys $nginxremote

scp /opt/nginx-make-installed.tar.gz $nginxremote:/usr/local
scp /opt/nginx.conf $nginxremote:/usr/local
scp /opt/nginx.service $nginxremote:/lib/systemd/system

ssh -tt $nginxremote << remotessh
    cd /usr/local
	tar -zxvf nginx-make-installed.tar.gz
	cd /usr/local/nginx/conf
	rm -rf nginx.conf 
	cp /usr/local/nginx.conf  /usr/local/nginx/conf
	sed -i 's/SDNC/$2/g' nginx.conf
	sed -i 's/SMS/$3/g' nginx.conf
	sed -i 's/NETCONF/$2/g' nginx.conf
	cd /usr/local/nginx/sbin
	chmod -R 777 nginx
	./nginx -s reload
	./nginx -s stop
	./nginx
	systemctl start firewalld
	firewall-cmd --permanent --add-port=3838/tcp
	firewall-cmd --permanent --add-port=8181/tcp
	firewall-cmd --permanent --add-port=4334/tcp
	systemctl restart firewalld
	systemctl enable nginx.service	
	systemctl enable firewalld
	exit
remotessh
echo "nginx is installed"
}


function genSshKeys() {
  if [ ! -e ~/.ssh/id_rsa ];then
    ssh-keygen -t rsa
  fi
}


function pushKeys() {
  echo "push keys to remote node:" $1
  remote=$1
  cat ~/.ssh/id_rsa.pub | ssh $remote "
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cat >> ~/.ssh/authorized_keys
    sort -u ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.bak
    mv ~/.ssh/authorized_keys.bak ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
  "
  ssh -n -o PasswordAuthentication=no $remote true
}

nginx_install $1 $2 $3
