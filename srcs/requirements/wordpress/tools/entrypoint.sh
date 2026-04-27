#!/bin/bash

echo "Waiting for mariadb to get started..."

# Waiting for MariaDB to be ready
until mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 1
done

echo "Mariadb is UP..."

# Check if wordpress is already downloaded
if [ ! -f wp-load.php ]; then
	# Download wordpress core files
	wp core download --allow-root

	# Create wordpress configuration file (wp-config.php)
	wp config create \
		--dbname=$MYSQL_DATABASE \
		--dbuser=$MYSQL_USER \
		--dbpass=$MYSQL_PASSWORD \
		--dbhost=$MYSQL_HOST \
		--allow-root
fi

# check if wordpress is already installed
if  ! wp core is-installed --allow-root; then
	# Launch the standard wordpress installation process
	wp core install \
		--url="https://$DOMAIN_NAME" \
		--title=$WORDPRESS_TITLE \
		--admin_user=$WORDPRESS_ADMIN_USER \
		--admin_password=$WORDPRESS_ADMIN_PASSWORD \
		--admin_email=$WORDPRESS_ADMIN_EMAIL \
		--allow-root

	# Create a normal user
	wp user create $WORDPRESS_USER $WORDPRESS_USER_EMAIL \
		--user_pass=$WORDPRESS_USER_PASSWORD \
		--allow-root

	# Configure redis caching
	wp config set WP_REDIS_HOST redis --allow-root
	wp config set WP_REDIS_PORT 6379 --allow-root
	wp config set WP_CACHE true --allow-root
	
	wp plugin install redis-cache --activate --allow-root

	wp redis enable --allow-root
fi

# Set permissions required by php-fpm that runs as www-data user
chown -R www-data:www-data /var/www/html
chmod -R 775 /var/www/html

# Start PHP-FPM
exec php-fpm8.2 -F