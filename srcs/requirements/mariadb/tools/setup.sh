#!/bin/sh
set -eu

DATADIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"
MARKER="$DATADIR/.inception-initialized"

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

case "$MYSQL_DATABASE" in
    ""|*[!a-zA-Z0-9_]*)
        echo "Error: Invalid database name"
        exit 1
        ;;
esac

case "$MYSQL_USER" in
    ""|*[!a-zA-Z0-9_]*)
        echo "Error: Invalid database user"
        exit 1
        ;;
esac

DB_PASSWORD_FILE="/run/secrets/db_password"
ROOT_PASSWORD_FILE="/run/secrets/db_root_password"

if [ ! -s "$DB_PASSWORD_FILE" ] || [ ! -s "$ROOT_PASSWORD_FILE" ]; then
    echo "Error: Missing or empty MariaDB secrets"
    exit 1
fi

MYSQL_PASSWORD=$(cat "$DB_PASSWORD_FILE")
MYSQL_ROOT_PASSWORD=$(cat "$ROOT_PASSWORD_FILE")

if [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Error: MariaDB secrets cannot be empty"
    exit 1
fi

escape_sql() {
    printf '%s' "$1" | sed "s/\\\\/\\\\\\\\/g; s/'/''/g"
}

MYSQL_PASSWORD_ESCAPED=$(escape_sql "$MYSQL_PASSWORD")
MYSQL_ROOT_PASSWORD_ESCAPED=$(escape_sql "$MYSQL_ROOT_PASSWORD")

mkdir -p /run/mysqld "$DATADIR"
chown mysql:mysql /run/mysqld "$DATADIR"

if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB system tables..."

    mariadb-install-db \
        --user=mysql \
        --datadir="$DATADIR" \
        --auth-root-authentication-method=socket \
        --skip-test-db
fi

if [ ! -f "$MARKER" ]; then
	echo "Configuring MariaDB..."

	mariadbd \
		--user=mysql \
		--datadir="$DATADIR" \
		--bootstrap \
		--skip-networking <<EOF
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;

CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%'
IDENTIFIED BY '$MYSQL_PASSWORD_ESCAPED';

ALTER USER '$MYSQL_USER'@'%'
IDENTIFIED BY '$MYSQL_PASSWORD_ESCAPED';

GRANT ALL PRIVILEGES
ON \`$MYSQL_DATABASE\`.*
TO '$MYSQL_USER'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED VIA unix_socket
OR mysql_native_password
USING PASSWORD('$MYSQL_ROOT_PASSWORD_ESCAPED');

FLUSH PRIVILEGES;
EOF

	touch "$MARKER"
fi

exec mariadbd \
	--user=mysql \
	--datadir="$DATADIR" \
	--socket="$SOCKET"

echo "Starting MariaDB..."

exec mariadbd \
    --user=mysql \
    --datadir="$DATADIR" \
    --socket="$SOCKET"