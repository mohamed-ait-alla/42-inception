#!/bin/bash

# Starting mysql service
mysqld_safe &

until mysqladmin ping --silent; do
    sleep 1
done

# Initializing Database
mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
mysql -e "FLUSH PRIVILEGES;"

mysqladmin -u root -p $MYSQL_ROOT_PASSWORD shutdown

wait

exec mysqld_safe
