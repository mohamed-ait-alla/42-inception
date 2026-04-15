#!/bin/bash

# create mysql socket directory
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# starting mysql service
mysqld_safe &

# waiting for it to get started
sleep 5

# initializing mysql users and database
mysql -h localhost -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# stoping mysql service to take new settings
mysql -h localhost -u root -p$MYSQL_ROOT_PASSWORD shutdown

wait

exec mysqld --user=mysql