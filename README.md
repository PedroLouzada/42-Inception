*This project has been created as part of the 42 curriculum by pbongiov.*

# Inception

## Description

Inception is a system administration project that deploys a WordPress website using Docker Compose.

The infrastructure contains three custom images, all built from Debian Bookworm:

- **NGINX** provides the only public entry point, on HTTPS port `443`.
- **WordPress** runs with PHP-FPM 8.2.
- **MariaDB** stores the WordPress database.

The services communicate through a user-defined bridge network:

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

Only NGINX publishes a port to the host. WordPress and MariaDB remain accessible only through the internal Docker network.

### Repository structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── 99-server.cnf
        │   └── tools/
        │       └── setup.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf
            └── tools/
                └── setup.sh
```

The directory structure separates responsibilities:

- `Makefile` provides the project-management commands.
- `docker-compose.yml` defines how the services work together.
- Each service directory contains its own Dockerfile and build context.
- `conf/` contains service configuration.
- `tools/` contains initialization and entrypoint scripts.
- `.env` provides non-sensitive runtime configuration.
- `secrets/` provides passwords without embedding them in images or Compose configuration.


## Instructions

Detailed operational instructions are available in:

- [`USER_DOC.md`](USER_DOC.md) for users and administrators.
- [`DEV_DOC.md`](DEV_DOC.md) for developers.

### Prerequisites

The project requires:

- Linux or a Linux virtual machine
- Docker Engine
- Docker Compose plugin
- GNU Make
- Port `443` available
- Internet access during the build and first WordPress initialization

### Hostname

The domain used by the project is:

```text
pbongiov.42.fr
```

When Docker and the browser run on the same machine, add this entry to `/etc/hosts`:

```text
127.0.0.1 pbongiov.42.fr
```

When Docker runs inside a virtual machine, use the virtual machine's IP instead of `127.0.0.1`.

### Environment configuration

You will need to have a "secrets" folder, and a .env file with the credentials.

### Build and start

From the repository root:

```bash
make
```

The Makefile builds the images and starts the stack in detached mode.

### Access

Website:

```text
https://pbongiov.42.fr
```

WordPress administration panel:

```text
https://pbongiov.42.fr/wp-admin/
```

The browser may warn about the self-signed TLS certificate generated during the NGINX image build.

### Stop and restart

Stop containers without removing them:

```bash
make stop
```

Start the existing containers:

```bash
make start
```

Remove the containers and project network while preserving volumes:

```bash
make down
```

Do not use `make fclean` or `make re` when the existing website and database data must be preserved.

## Resources

The following official resources were used:

- [Docker overview](https://docs.docker.com/get-started/docker-overview/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker secrets in Compose](https://docs.docker.com/compose/how-tos/use-secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI documentation](https://make.wordpress.org/cli/handbook/)

### Use of AI

AI was used as a learning and documentation assistant.

It helped explain Docker concepts such as images, containers, Compose, bridge networking, process lifecycle, PID 1, foreground services, and differences between containers and virtual machines.