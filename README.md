# Inception

## 🐳 About the Project

**Inception** is a system administration and DevOps project from the 42 curriculum.

Its goal is to build a small, secure web infrastructure using **Docker**, with every service running in its own container and orchestrated through **Docker Compose**.

The project brings together **NGINX**, **WordPress with PHP-FPM**, and **MariaDB** inside a Linux virtual machine. Each image is built from its own Dockerfile, the services communicate through a dedicated Docker network, and persistent data is stored in named volumes.

Inception pushed me to understand what happens between writing a configuration file and serving a working website: image builds, container startup, process management, networking, TLS, secrets, storage, and service dependencies.

---

## 🧠 What I Learned

- Understanding the difference between **virtual machines**, **Docker images**, and **containers**.
- Writing custom **Dockerfiles** and keeping the main service process in the foreground.
- Orchestrating multiple services with **Docker Compose**.
- Creating an isolated **Docker network** and using service names for container-to-container communication.
- Configuring **NGINX** as the only public entry point, with HTTPS through **TLS 1.2 and TLS 1.3**.
- Connecting NGINX to **WordPress and PHP-FPM** through FastCGI.
- Installing and configuring **WordPress** automatically with WP-CLI.
- Initializing **MariaDB** safely and making startup scripts idempotent.
- Preserving WordPress files and database data with **Docker named volumes**.
- Keeping passwords out of images and source control with **Docker secrets**.
- Managing startup order, health checks, restart policies, logs, and failure recovery.
- Debugging permissions, networking, DNS resolution, and service readiness across containers.

---

## 🏗️ Architecture

```text
Browser
   |
   | HTTPS :443
   v
 NGINX
   |
   | FastCGI :9000
   v
WordPress + PHP-FPM
   |
   | MySQL protocol :3306
   v
 MariaDB

Persistent storage:
- WordPress files → named volume
- MariaDB data    → named volume

All services communicate through a private Docker network.
Only NGINX exposes a port to the host.
```

---

## ⚙️ Features Implemented

### ✅ Core Infrastructure

- Three isolated services, each running in its own container:
  - **NGINX**
  - **WordPress with PHP-FPM**
  - **MariaDB**
- Custom image for every service, built from its own Dockerfile.
- Complete stack managed through Docker Compose and a root Makefile.
- Dedicated bridge network for internal service communication.
- Automatic restart policy for service recovery.

### 🔒 Security and Reliability

- HTTPS on port `443`, with only TLS 1.2 and TLS 1.3 enabled.
- NGINX is the only service exposed to the host.
- Passwords and credentials are stored outside the repository.
- No passwords are hard-coded in Dockerfiles or committed configuration.
- Entrypoint scripts can run repeatedly without duplicating or corrupting the installation.
- WordPress and database data survive container recreation.

### 💾 Persistent Data

- A named volume stores the WordPress website files.
- A separate named volume stores the MariaDB database.
- Removing and recreating containers does not remove application data.

---

## 🖥️ How to Use

### Prerequisites

- A Linux virtual machine
- Docker Engine
- Docker Compose plugin
- GNU Make
- Local environment and secret files required by the project configuration

### Clone and Start the Project

```bash
git clone git@github.com:PedroLouzada/42-Inception.git
cd 42-Inception
make
```

Add the project domain to the machine that will access the website:

```text
<VM-IP> <login>.42.fr
```

Then open:

```text
https://<login>.42.fr
```

Because the project uses a self-signed certificate, the browser may display a warning on the first visit.

### Stop the Infrastructure

```bash
make down
```

Use the repository's documented cleanup target only when you intentionally want to remove persistent data.

---

## 🔍 Infrastructure Rules and Behavior

- Each service runs in a dedicated container.
- Containers are built from the penultimate stable release of Debian or Alpine.
- Application images are built locally instead of using ready-made NGINX, WordPress, or MariaDB images.
- Containers communicate through the Docker network using service names, not `localhost`.
- NGINX terminates TLS and forwards PHP requests to WordPress through FastCGI.
- WordPress connects to MariaDB through the internal Docker network.
- Only NGINX publishes a port to the host.
- The primary process of each container runs in the foreground as PID 1.
- Named volumes keep important data outside the lifecycle of individual containers.
- Secrets remain outside images and version control.

---

## 🚀 Future Improvements

- Add automated integration tests for service health, networking, TLS, and persistence.
- Add backup and restore commands for WordPress files and MariaDB data.
- Improve observability with clearer health checks and structured logs.
- Harden container permissions and reduce image size where practical.
- Explore optional services such as Redis, Adminer, FTP, or a static website after the mandatory stack is stable.

---

## 💡 Final Thoughts

Inception changed the way I think about software deployment.

Instead of focusing on a single program, I had to reason about an entire system: how services start, communicate, fail, recover, and preserve their data.

The project made Docker feel much less like a collection of commands and much more like a practical model for building reproducible infrastructure.

It was challenging, especially when a problem crossed several layers at once, but seeing the complete **HTTPS → NGINX → WordPress → MariaDB** flow working made the effort worth it.

---

## 📚 Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress CLI documentation](https://make.wordpress.org/cli/handbook/)
- [MariaDB documentation](https://mariadb.com/docs/)

---

## 📬 Contact

[GitHub](https://github.com/PedroLouzada)
