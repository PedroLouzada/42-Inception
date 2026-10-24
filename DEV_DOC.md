# Inception Developer Guide

## Overview

This document explains how to configure, build, inspect, debug, and maintain the Inception development environment.

For routine operation, website access, administration, and credential management, see [`USER_DOC.md`](USER_DOC.md).

## Architecture

The project runs three main services:

```text
Browser
  │  HTTPS :443
  ▼
┌─────────────────────────────────────────┐
│  Docker bridge network: "inception"     │
│                                         │
│  ┌──────────────────────┐               │
│  │  NGINX (port 443)    │               │
│  │  TLSv1.2 / TLSv1.3   │               │
│  └──────────┬───────────┘               │
│             │ FastCGI (port 9000)       │
│  ┌──────────▼───────────┐               │
│  │  WordPress + php-fpm │               │
│  └──────────┬───────────┘               │
│             │ MySQL protocol (port 3306)│
│  ┌──────────▼───────────┐               │
│  │  MariaDB             │               │
│  └──────────────────────┘               │
└─────────────────────────────────────────┘

```

- **NGINX** is the only public entry point and exposes HTTPS on port `443`.
- **WordPress** runs with PHP-FPM and receives FastCGI requests from NGINX.
- **MariaDB** stores the WordPress database.
- The services communicate through a user-defined Docker bridge network.
- WordPress files and MariaDB data are stored outside the containers for persistence.

Only NGINX should publish a host port. WordPress and MariaDB remain accessible through the internal Docker network.

## Prerequisites

The recommended environment is Linux or a Linux virtual machine with:

- Docker Engine
- Docker Compose plugin
- GNU Make
- Git
- Administrator access for configuring `/etc/hosts`
- Port `443` available on the host

Check the installed tools:

```bash
docker --version
docker compose version
make --version
git --version
```

Confirm that Docker is running:

```bash
docker info
```

## Repository structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
└── srcs
    ├── .env
    ├── docker-compose.yml
    └── requirements
        ├── mariadb
        │   ├── Dockerfile
        │   ├── conf
        │   └── tools
        ├── nginx
        │   ├── Dockerfile
        │   ├── conf
        │   └── tools
        └── wordpress
            ├── Dockerfile
            ├── conf
            └── tools
```

Responsibilities are separated as follows:

- `Makefile` provides the main project-management commands.
- `srcs/docker-compose.yml` defines services, builds, networks, volumes, and secrets.
- `srcs/.env` contains non-sensitive Compose configuration.
- `requirements/<service>/Dockerfile` builds one service image.
- `conf/` contains service configuration files.
- `tools/` contains initialization and entrypoint scripts.
- Secret files contain sensitive values and must not be committed.

## Initial setup

## Environment configuration

Set the non-sensitive project configuration in `srcs/.env`.

The project domain should be:

```env
DOMAIN_NAME=pbongiov.42.fr
```

The file may also contain values such as:

- Database name.
- Database username.
- WordPress site title.
- Non-sensitive WordPress usernames.

Passwords must be provided through the secret mechanism defined in `srcs/docker-compose.yml`.

Passwords must not be:

- Hard-coded in a Dockerfile.
- Hard-coded in `docker-compose.yml`.
- Stored in a committed `.env` file.
- Printed to logs.
- Added to documentation.

## Build contexts

Each service should have its own build context:

```yaml
services:
  nginx:
    build:
      context: ./requirements/nginx

  wordpress:
    build:
      context: ./requirements/wordpress

  mariadb:
    build:
      context: ./requirements/mariadb
```

A build context defines which files Docker can access while building an image.

Separate build contexts:

- Keep the services independent.
- Reduce the amount of data sent to the Docker builder.
- Prevent unrelated files from being copied accidentally.
- Improve build-cache reuse.
- Clarify which files belong to each image.

Use `.dockerignore` files when necessary to exclude temporary files, repository metadata, and local credentials.

## Makefile usage

The Makefile is the main interface for managing the project. The definitions in the repository's Makefile are authoritative.

Typical targets include:

| Command | Purpose |
|---|---|
| `make` or `make all` | Build and start the complete stack |
| `make build` | Build the service images |
| `make up` | Start the stack |
| `make down` | Stop and remove containers and the project network |
| `make clean` | Remove generated container resources |
| `make fclean` | Perform a complete cleanup |
| `make re` | Rebuild the project |

Start the project from the repository root:

```bash
make
```

After changing a Dockerfile, service configuration, or initialization script, rebuild the affected service or run:

```bash
make re
```

Before executing cleanup targets, inspect their definitions. Cleanup must distinguish disposable Docker resources from persistent application data.

## Docker Compose commands

The following commands can be used directly for development and debugging.

### Validate the configuration

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml config
```

### Build all images

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml build
```

### Build without cache

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml build --no-cache
```

### Build one service

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml build nginx
```

Replace `nginx` with `wordpress` or `mariadb` when required.

### Start the stack

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d
```

Build changed images while starting:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d --build
```

### Check service status

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps
```

### Stop containers without removing them

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml stop
```

### Start stopped containers

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml start
```

### Restart one service

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml restart nginx
```

### Remove containers and the project network

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml down
```

Named volumes are preserved unless the `--volumes` option is added.

## Logs and debugging

Display all service logs:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs
```

Follow logs in real time:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f
```

Display the latest logs for one service:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs --tail=100 mariadb
```

Run a diagnostic command inside a service:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec <service> <command>
```

For example, if the image contains `sh`:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml exec nginx sh
```

A debugging shell may be used interactively. It must not be used as the container's main process.

Inspect Docker resources:

```bash
docker container ls
docker image ls
docker network ls
docker volume ls
```

Test the HTTPS endpoint:

```bash
curl -k -I https://pbongiov.42.fr
```

## Debugging order

When a service does not work:

1. Validate the Compose file with `docker compose config`.
2. Check container state with `docker compose ps`.
3. Read the failing service's logs.
4. Confirm that all required secret files exist.
5. Confirm that service names are used as internal hostnames.
6. Confirm that services share the intended Docker network.
7. Check host-directory ownership and permissions.
8. Rebuild the affected image if its Dockerfile or copied files changed.

`depends_on` can control container startup order, but it does not necessarily guarantee that an application is ready to accept connections. Initialization scripts should tolerate dependency startup time when necessary.

## Container process model

Each container should run its actual service as its main foreground process:

```text
NGINX container     → nginx
WordPress container → php-fpm
MariaDB container   → mariadbd
```

Entrypoint scripts may perform initialization before starting the service, but should finish with `exec`:

```sh
exec <service-command>
```

This replaces the shell with the service process, allowing Docker to receive the correct exit status and deliver stop signals correctly.

Containers must not be kept alive artificially with `tail -f`, an interactive shell, or an unrelated infinite loop.

## Data persistence

Container filesystems are disposable. Persistent application state must be stored through the volumes defined in `srcs/docker-compose.yml`.

The project normally persists:

- MariaDB data under `/home/pbongiov/data/mariadb`.
- WordPress files under `/home/pbongiov/data/wordpress`.

The exact host paths and container mount points declared in `docker-compose.yml` are authoritative.

Rebuilding or recreating a container should not delete persistent data:

```bash
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d --build
```

Initialization logic should be idempotent. It should create the database or WordPress installation only when the corresponding persistent data does not already exist.

Changing an initialization password in a secret file does not automatically update an existing database account. Existing state must be migrated explicitly.