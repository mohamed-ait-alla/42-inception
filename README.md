*This project has been created as part of the **42 curriculum** by **mait-all**.*

---

# Inception

A Docker-based infrastructure project built as part of the 42 school curriculum. The project involves setting up a small but complete web server environment using Docker Compose, with each service running in its own container.

---

## Table of Contents

- [Description](#description)
- [Architecture Overview](#architecture-overview)
- [Design Choices](#design-choices)
- [Instructions](#instructions)
- [Services](#services)
- [Resources](#resources)

---

## Description

Inception is a system administration and DevOps project that requires building a fully functional multi-container infrastructure using Docker and Docker Compose. The goal is to deepen understanding of containerization, service orchestration, networking, and persistent storage — all from scratch, without using pre-built images from Docker Hub (except the base OS image).

The infrastructure is composed of the following mandatory services:

- **NGINX** — the single entry point, serving over HTTPS (TLS 1.2/1.3 only)
- **WordPress + php-fpm** — the application layer
- **MariaDB** — the database backend

And the following bonus services:

- **Redis** — object cache for WordPress
- **FTP Server (vsftpd)** — file access to the WordPress volume
- **Adminer** — lightweight database management UI
- **Static Website** — a simple static page served alongside the main application
- And at least an extra service of your choice

All containers are built from `debian:12` base images using custom Dockerfiles. No pre-built service images are used.

---

## Architecture Overview

```
                        ┌─────────────────────────────────────────┐
                        │              Host Machine               │
                        │                                         │
                        │   https://localhost (port 443)          │
                        │   ftp://localhost   (port 21)           │
                        │   http://localhost/adminer (port 443)   │
                        └────────────────┬────────────────────────┘
                                         │
                              ┌──────────▼──────────┐
                              │       NGINX         │
                              │   (TLS termination) │
                              └──┬──────────────┬───┘
                                 │              │
                    ┌────────────▼───┐    ┌─────▼──────────┐
                    │   WordPress    │    │    Adminer     │
                    │   php-fpm:9000 │    │    php:8080    │
                    └────────┬───────┘    └────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼──────┐  ┌────▼────┐  ┌─────▼──────┐
     │   MariaDB     │  │  Redis  │  │  FTP Server│
     │   port 3306   │  │  :6379  │  │  port 21   │
     └───────────────┘  └─────────┘  └────────────┘
```

All services communicate over a custom Docker bridge network called `inception`.

---

## Design Choices

### Virtual Machines vs Docker

| | Virtual Machines | Docker Containers |
|---|---|---|
| **Isolation** | Full OS-level isolation, separate kernel | Process-level isolation, shared kernel |
| **Boot time** | Minutes | Milliseconds |
| **Resource usage** | Heavy — each VM runs a full OS | Lightweight — shares host OS kernel |
| **Portability** | Harder to move between environments | Highly portable via images |
| **Use case** | Full system emulation, different OS | Application packaging and microservices |

For this project, Docker is the right tool because each service (nginx, wordpress, mariadb) is an isolated process with its own dependencies, not a full operating system. Docker gives us reproducibility and isolation without the overhead of running multiple virtual machines.

### Secrets vs Environment Variables

| | Secrets | Environment Variables |
|---|---|---|
| **Storage** | Encrypted at rest, mounted as files | Stored in plain text in compose or shell |
| **Visibility** | Not visible in `docker inspect` | Visible in `docker inspect` output |
| **Access** | Only accessible by services that need them | Accessible by any process in the container |
| **Use case** | Passwords, API keys, certificates | Non-sensitive config (ports, hostnames) |

In a production environment, Docker secrets are always preferred for sensitive values like database passwords. In this project, `.env` files are used for convenience since it runs on a local machine — but they are excluded from version control via `.gitignore`.

### Docker Network vs Host Network

| | Docker Network (bridge) | Host Network |
|---|---|---|
| **Isolation** | Containers have their own network namespace | Containers share the host's network stack |
| **Security** | Services only communicate through defined channels | Any service can access any host port |
| **Port mapping** | Explicit port mapping required | No mapping needed, direct host access |
| **DNS** | Docker provides internal DNS (service names) | No internal DNS, must use IPs |

This project uses a custom **bridge network** (`inception`) so that containers communicate using service names (e.g. `wordpress`, `mariadb`, `redis`) as hostnames, while remaining isolated from the host network. Only required ports are explicitly exposed.

### Docker Volumes vs Bind Mounts

| | Named Volumes | Bind Mounts |
|---|---|---|
| **Management** | Managed by Docker | Managed by the host filesystem |
| **Portability** | Fully portable across environments | Tied to a specific host path |
| **Performance** | Optimized by Docker | Depends on host filesystem |
| **Use case** | Persistent data (DB, app files) | Dev workflows, config file injection |

This project uses **named volumes** with `driver_opts` to store data at `/home/login/data` on the host, as required by the subject. This satisfies both requirements: data persists across container restarts, and the storage location on the host is predictable and explicit.

---

## Instructions

### Prerequisites

- `Docker`
- `Docker Compose`
- `make`

### Setup

Clone the repository:
```bash
https://github.com/Mohamed-ait-alla/42-inception.git
cd 42-inception
```

Create a `.env` file in `srcs/`:
```bash
# Domain name
DOMAIN_NAME=login.42.fr

# Database
MYSQL_HOST=mariadb
MYSQL_DATABASE=wordpress
MYSQL_USER=your_db_user
MYSQL_PASSWORD=your_db_user_password
MYSQL_ROOT_PASSWORD=your_root_password

# WordPress
WORDPRESS_TITLE=your_wp_title
WORDPRESS_ADMIN_USER=your_admin_user
WORDPRESS_ADMIN_PASSWORD=your_admin_password
WORDPRESS_ADMIN_EMAIL=your_admin_email
WORDPRESS_USER=your_normal_wp_user
WORDPRESS_USER_EMAIL=your_normal_user_email
WORDPRESS_USER_PASSWORD=your_normal_user_password

# FTP
FTP_USER=your_ftp_user
FTP_PASSWORD=your_ftp_password
```

Edit your `/etc/hosts` file to map your domain locally:
```bash
# Debian/Linux
sudo nano /etc/hosts
```

And add the following line:
```bash
127.0.0.1    login.42.fr
```

### Build and Run

```bash
make        # builds images, creates directories, starts all containers
make down   # stops all containers
make clean  # stops containers and removes data
make fclean # full cleanup including images and volumes
make re     # full rebuild from scratch
```

### Access the Services

| Service | URL |
|---|---|
| WordPress | https://login.42.fr |
| Adminer | https://login.42.fr/adminer |

> **Note:** Since NGINX uses a self-signed certificate, your browser will show a security warning. This is expected — proceed by accepting the certificate.

---

## Services

### NGINX
The sole entry point to the infrastructure. Listens on port 443 with TLS 1.2/1.3 only. Acts as a reverse proxy to WordPress (via FastCGI) and Adminer (via HTTP proxy).

### WordPress + php-fpm
WordPress is configured and installed automatically at container startup using WP-CLI. php-fpm listens on port 9000 and processes PHP requests forwarded by NGINX.

### MariaDB
The database backend for WordPress. Initialized with a custom entrypoint script that creates the database, users, and sets passwords from environment variables.

### Redis
Object cache for WordPress. Configured via the `redis-cache` WordPress plugin, enabled automatically during WordPress setup. Reduces database load by caching query results in memory.

### FTP Server (vsftpd)
Provides file-level access to the WordPress volume. Runs in passive mode with a dedicated port range (21100–21110). The FTP user is chrooted to `/var/www/html`.

### Adminer
A single-file PHP database management tool. Served through NGINX at `/adminer` as a reverse proxy. Allows browsing and managing the WordPress MariaDB database through a web UI.

### Portainer
A web-based Docker management UI. Served through NGINX at `/portainer` as a reverse proxy. Allows managing containers, images, volumes, and networks through a visual interface without using the command line.
 
### cAdvisor
A container resource monitoring tool developed by Google. Served through NGINX  at `/cadvisor` as a reverse proxy. Provides real-time metrics on CPU, memory, network, and filesystem usage for all running containers.


---

## Resources

### Docker & Containerization
- [Docker official documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker networking overview](https://docs.docker.com/network/)
- [Docker volumes documentation](https://docs.docker.com/storage/volumes/)
- [Docker crach course (video)](https://www.youtube.com/watch?v=zJ6WbK9zFpI&t=905s)
- [Docker networking (video)](https://www.youtube.com/watch?v=bKFMS5C4CG0)
### Services
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress WP-CLI documentation](https://wp-cli.org/)
- [vsftpd documentation](https://security.appspot.com/vsftpd.html)
- [Redis documentation](https://redis.io/docs/)
- [Adminer documentation](https://www.adminer.org/)

### TLS / SSL
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [OpenSSL man page](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html)

### other
- [namespaces and cgroups](https://jvns.ca/blog/2016/10/10/what-even-is-a-container/)
- [container runtimes](https://www.ianlewis.org/en/container-runtimes-part-1-introduction-container-r?ref=devopscube.com)
- [what is docker?](https://devopscube.com/what-is-docker/)

### AI Usage

AI tools was used throughout this project as a **learning and debugging assistant**, specifically for:
- Debugging and interpreting service and container error messages
- Understanding best practices for Docker and service configuration
- Improve documentation clarity and structure

AI was used strictly as an assistant to understand concepts, not to blindly generate complete solutions. All code was reviewed, understood, and adapted manually.