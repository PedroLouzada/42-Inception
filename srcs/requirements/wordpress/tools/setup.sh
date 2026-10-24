#!/bin/sh
set -eu

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

cd /var/www/html

echo "Waiting for MariaDB..."

until mariadb-admin ping -h mariadb --silent >/dev/null 2>&1; do
    sleep 2
done

if [ ! -f wp-load.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
    echo "Configuring WordPress..."

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306 \
        --allow-root
fi

if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
fi

if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    echo "Creating WordPress user..."

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root
fi

chown -R www-data:www-data /var/www/html

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F