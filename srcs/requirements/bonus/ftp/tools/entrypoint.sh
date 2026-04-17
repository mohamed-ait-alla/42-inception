#!/bin/bash

mkdir -p /var/run/vsftpd/empty
chmod 755 /var/run/vsftpd/empty


useradd -m -d /var/www/html $FTP_USER
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

chown -R $FTP_USER:$FTP_USER /var/www/html

exec vsftpd /etc/vsftpd.conf