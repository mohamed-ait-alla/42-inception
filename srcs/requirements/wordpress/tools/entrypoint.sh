#!/bin/bash

echo "Waiting for mariadb to get started..."

# Wait for MariaDB
until mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 1
done

echo "Mariadb is UP..."

if [ ! -f wp-load.php ]; then
	wp core download --allow-root
	wp config create \
		--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$MYSQL_PASSWORD \
		--dbhost=$MYSQL_HOST \
		--allow-root
fi

if  ! wp core is-installed --allow-root; then
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

	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT 6379 --allow-root
	wp config set WP_CACHE true --allow-root
	
	wp plugin install redis-cache --activate --allow-root

	wp redis enable --allow-root
fi

chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

# Start PHP-FPM
exec php-fpm8.2 -F