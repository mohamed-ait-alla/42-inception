#!/bin/bash

# Wait for MariaDB
until mysqladmin ping -h mariadb --silent; do
    echo "sleeping..."
    sleep 1
done

cd /var/www/wordpress

if [ ! -f wp-config.php ]; then
	# Create wp-config.php
	wp config create \
		--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$MYSQL_PASSWORD \
		--dbhost=$MYSQL_HOST \
		--allow-root
fi

if  ! wp core is-installed --allow-root; then
	# Install WordPress
	wp core install \
		--url=$WORDPRESS_URL \
		--title=$WORDPRESS_TITLE \
		--admin_user=$WORDPRESS_ADMIN_USER \
		--admin_password=$WORDPRESS_ADMIN_PASSWORD \
		--admin_email=$WORDPRESS_ADMIN_EMAIL \
		--allow-root

	# Create a normal user
	wp user create $WORDPRESS_USER $WORDPRESS_USER_EMAIL \
		--user_pass=$WORDPRESS_USER_PASSWORD \
		--allow-root
fi

# Start PHP-FPM
exec php-fpm8.2 -F