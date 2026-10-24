#!/bin/sh
set -e

DATADIR="/var/lib/mysql"
MARKER="$DATADIR/.initialized"

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "$DATADIR/mysql" ]; then
    mariadb-install-db --user=mysql --datadir="$DATADIR"
fi

if [ ! -f "$MARKER" ]; then
    echo "Configuring MariaDB..."

    mariadbd --user=mysql --bootstrap <<EOF
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;

CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%'
IDENTIFIED BY '$MYSQL_PASSWORD';

GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.*
TO '$MYSQL_USER'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';

FLUSH PRIVILEGES;
EOF

    touch "$MARKER"
fi

echo "Starting MariaDB..."

exec mariadbd --user=mysql --bind-address=0.0.0.0