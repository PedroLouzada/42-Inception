#!/bin/sh

set -eu

DB_PASSWORD_FILE="/run/secrets/db_password"
WP_ADMIN_PASSWORD_FILE="/run/secrets/wp_admin_password"
WP_USER_PASSWORD_FILE="/run/secrets/wp_user_password"

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${WP_TITLE:?WP_TITLE is required}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

for secret_file in \
    "$DB_PASSWORD_FILE" \
    "$WP_ADMIN_PASSWORD_FILE" \
    "$WP_USER_PASSWORD_FILE"
do
    if [ ! -s "$secret_file" ]; then
        echo "Error: Missing or empty secret: $secret_file"
        exit 1
    fi
done

RUNTIME_DB_PASSWORD_FILE="/run/wordpress-db-password"

install \
    -o www-data \
    -g www-data \
    -m 0400 \
    "$DB_PASSWORD_FILE" \
    "$RUNTIME_DB_PASSWORD_FILE"

ADMIN_USER_LOWER=$(printf '%s' "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')

case "$ADMIN_USER_LOWER" in
    *admin*)
        echo "Error: WP_ADMIN_USER cannot contain 'admin'"
        exit 1
        ;;
esac

if [ "$WP_ADMIN_USER" = "$WP_USER" ]; then
    echo "Error: WordPress users must be different"
    exit 1
fi

mkdir -p /run/php /var/www/html
cd /var/www/html

DB_CLIENT_CONFIG="/run/wordpress-db.cnf"

umask 077

{
    printf '[client]\n'
    printf 'host=mariadb\n'
    printf 'user=%s\n' "$MYSQL_USER"
    printf 'password=%s\n' "$(cat "$DB_PASSWORD_FILE")"
} > "$DB_CLIENT_CONFIG"

cleanup() {
    rm -f "$DB_CLIENT_CONFIG"
}

trap cleanup EXIT HUP INT TERM

echo "Waiting for MariaDB..."

i=0

until mariadb-admin \
    --defaults-extra-file="$DB_CLIENT_CONFIG" \
    ping \
    --silent >/dev/null 2>&1
do
    i=$((i + 1))

    if [ "$i" -ge 30 ]; then
        echo "Error: MariaDB connection timed out"
        exit 1
    fi

    sleep 2
done

rm -f "$DB_CLIENT_CONFIG"
trap - EXIT HUP INT TERM

if [ ! -f wp-load.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
fi

if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."

    wp config create \
        --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="temporary-value" \
        --dbhost="mariadb:3306" \
        --skip-check
fi

wp config set \
    DB_PASSWORD \
    "trim(file_get_contents('/run/wordpress-db-password'))" \
    --raw \
    --allow-root

if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    wp core install \
        --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --prompt=admin_password \
        < "$WP_ADMIN_PASSWORD_FILE"
fi

if ! wp user get "$WP_USER" --allow-root >/dev/null 2>&1; then
    echo "Creating regular WordPress user..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --allow-root \
        --role=author \
        --prompt=user_pass \
        < "$WP_USER_PASSWORD_FILE"
fi

chown -R www-data:www-data /var/www/html

echo "Starting PHP-FPM..."

exec /usr/sbin/php-fpm8.2 -F