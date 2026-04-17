#!/bin/bash

# initializing the security staging area used by vsftpd for privilege dropping process
mkdir -p /var/run/vsftpd/empty
chmod 755 /var/run/vsftpd/empty


# setting up ftp user
useradd -m -d /var/www/html $FTP_USER
echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

usermod -aG www-data $FTP_USER

# start vsftpd in foreground
exec vsftpd /etc/vsftpd.conf