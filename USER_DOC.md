# Inception User Guide

## Overview

This guide explains how an end user or administrator can operate the Inception stack, access the WordPress website and administration panel, manage credentials, and perform basic checks.

For build details, development commands, and data persistence, see [`DEV_DOC.md`](DEV_DOC.md).

## Start the stack

From the repository root, run:

```bash
make
```

Wait until all services have started before opening the website.

Check their status with:

```bash
make ps
```

The following services should be running:

- `nginx`
- `wordpress`
- `mariadb`

## Stop the stack

From the repository root, run:

```bash
make down
```

Stopping the stack does not normally delete the persistent WordPress or MariaDB data.

To stop the containers without removing them:

```bash
make stop
```

To start stopped containers again:

```bash
make start
```

## Access the website

Open the following address in a browser:

```text
https://pbongiov.42.fr
```

The hostname must resolve to the machine running Docker. For local access, `/etc/hosts` should contain:

```text
127.0.0.1 pbongiov.42.fr
```

The browser may display a warning if the project uses a self-signed TLS certificate. Confirm that the address is `pbongiov.42.fr` before continuing.

## Access the WordPress administration panel

Open:

```text
https://pbongiov.42.fr/wp-admin
```

Sign in with the WordPress administrator credentials configured during the initial deployment.

The administration panel can be used to:

- Create and edit posts and pages.
- Manage WordPress users.
- Change WordPress user passwords.
- Configure themes and plugins.
- Modify website settings.

## Manage credentials

Passwords and other sensitive values must not be:

- Hard-coded in Dockerfiles.
- Hard-coded in `docker-compose.yml`.
- Added to documentation.
- Printed in logs.
- Committed to Git.

Sensitive values should be stored in the secret files referenced by `srcs/docker-compose.yml`. Non-sensitive configuration values may be stored in `srcs/.env`.

Recommended practices:

- Use strong and unique passwords.
- Restrict secret-file access to authorized users.
- Back up persistent data before rotating database credentials.
- Keep secret files excluded from Git.



### Change a WordPress password

For an existing WordPress user:

1. Open `https://pbongiov.42.fr/wp-admin`.
2. Sign in as an administrator.
3. Open **Users**.
4. Select the account.
5. Generate or enter a new password.
6. Save the changes.

Changing an initialization secret does not automatically update an existing WordPress account because the account is already stored in MariaDB.

### Change database credentials

The credentials used by WordPress must match the MariaDB application-user credentials.

Changing only one side will prevent WordPress from connecting to the database.

To rotate database credentials safely:

1. Back up the database.
2. Change the MariaDB user's password.
3. Update the corresponding secret used by WordPress.
4. Restart or recreate the affected services.
5. Confirm that the website still works.
6. Review the WordPress and MariaDB logs.

Do not remove the MariaDB volume merely to apply a new password. Removing persistent data may permanently delete the website database.

## Basic checks

### Check the containers

```bash
make ps
```

### Check the website

```bash
curl -k -I https://pbongiov.42.fr
```

The response should contain a successful HTTP status or a valid redirect, such as:

```text
HTTP/1.1 200 OK
```

or:

```text
HTTP/1.1 301 Moved Permanently
```

### View all service logs

```bash
docker compose -f srcs/docker-compose.yml logs
```

### View logs for one service

```bash
docker compose -f srcs/docker-compose.yml logs --tail=50 nginx
```

Replace `nginx` with `wordpress` or `mariadb` when checking another service.

### Follow logs in real time

```bash
docker compose -f srcs/docker-compose.yml logs -f
```
