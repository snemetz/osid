#!/bin/bash
#
# Setup OSID on Arch Linux
#
# Tested with OSID v1.1

RepoSource='https://github.com/snemetz/osid.git'

# Do not change directories. This does not modify OSID yet
BaseDir='/etc/osid'
ImageDir="$BaseDir/imgroot"
SystemDir="$BaseDir/system"
WebDir="$BaseDir/www/public_html"

if [ -f /etc/arch-release ]; then
  # Running on Arch
  cmd_pkg_install='pacman -Syu'
  cmd_enable='systemctl enable XXX'
  cmd_restart='systemctl restart XXX'
  # package list
fi
# TODO: Add code for Raspbian, Fedora

#hostnamectl set-hostname osid
pacman -Syu unzip git nginx php-fpm dcfldd cronie samba
git clone $RepoSource $BaseDir
mkdir -p $ImageDir
chown http:http -R $ImageDir $SystemDir $WebDir

# Setup web server
cat > /etc/nginx/nginx.conf <<NGINX
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 80;
        server_name localhost;
        root $WebDir;
        location / {
            index index.html index.htm index.php;
        }

        location ~ \.php$ {
            #fastcgi_pass 127.0.0.1:9000; (depending on your php-fpm socket configuration)
            fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
            fastcgi_index index.php;
            include fastcgi.conf;
        }
    }

}
NGINX

# Allow PHP to access OSID and image directories
sed -i "/^open_basedir/ s#$#:$WebDir:$SystemDir:$ImageDir#" /etc/php/php.ini
# Setup crontab
crontab <<CRON
* * * * * $SystemDir/write.sh
CRON

# Setup file sharing. So images can be uploaded
cat > /etc/samba/smb.conf <<SAMBA
[global]
workgroup = WORKGROUP
server string = Open Source Image Duplicator
map to guest = Bad User
security = user

log file = /var/log/samba/%m.log
max log size = 50

interfaces = lo eth0
guest account = http

dns proxy = no

[Images]
path = $ImageDir
public = yes
only guest = yes
writable = yes
SAMBA

# TODO: Change directories in OSID code

# Setup everything to autostart with the system
systemctl enable cronie
systemctl enable nginx
systemctl enable php-fpm
systemctl enable smbd
# Make sure everything is running with current configurations
systemctl restart cronie
systemctl restart php-fpm
systemctl restart nginx
systemctl restart smbd

