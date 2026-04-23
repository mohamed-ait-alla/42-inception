# User Documentation — Inception

This document explains how to start, access, and manage the Inception infrastructure as an end user or administrator.

---

## Table of Contents

- [What Services Are Provided](#what-services-are-provided)
- [Starting and Stopping the Project](#starting-and-stopping-the-project)
- [Accessing the Services](#accessing-the-services)
- [Credentials](#credentials)
- [Checking That Services Are Running](#checking-that-services-are-running)

---

## What Services Are Provided

The Inception stack runs the following services, each in its own Docker container:

| Service | Role | Access |
|---|---|---|
| **NGINX** | Main entry point, handles HTTPS and routes traffic | Transparent — all requests go through it |
| **WordPress** | The main website and blog platform | https://localhost |
| **MariaDB** | Database that stores all WordPress content | Internal only (not exposed to host) |
| **Redis** | Cache layer that speeds up WordPress | Internal only |
| **Adminer** | Web UI to browse and manage the database | https://localhost/adminer |
| **Portainer** | Web UI to manage Docker containers and images | https://localhost/portainer |
| **cAdvisor** | Real-time container resource monitoring | https://localhost/cadvisor |
| **FTP Server** | File access to WordPress files | ftp://localhost (port 21) |

> All web services are served over HTTPS through NGINX. MariaDB and Redis are internal services and cannot be accessed directly from outside the stack.

---

## Starting and Stopping the Project

### Requirements

Before starting, make sure the following are installed on your machine:

- `Docker`
- `Docker Compose`
- `make`

### Start the project

```bash
make
```

This will:
1. Create the required data directories on your host (`/home/mait-all/data/mariadb` and `/home/mait-all/data/wordpress` and `/home/mait-all/data/portainer`)
2. Build all Docker images from their Dockerfiles
3. Start all containers in the correct order

### Stop the project

```bash
make down
```

Stops all running containers without removing any data. You can restart with `make` afterwards and everything will be preserved.

### Full reset

```bash
make fclean
```

Stops all containers and removes all images, volumes, and data. Use this only if you want to start completely from scratch.

```bash
make re
```

Shortcut for `make fclean` followed by `make` — a full rebuild from zero.

---

## Accessing the Services

> **Important:** NGINX uses a self-signed SSL certificate. Your browser will show a security warning on first visit. This is expected — click **Advanced** then **Proceed** to continue.

### WordPress (main website)

Open your browser and go to:
```
https://localhost
```

The WordPress site will load. To access the WordPress admin dashboard:
```
https://localhost/wp-admin
```

Log in with the admin credentials defined in your `.env` file (see [Credentials](#credentials)).

### Adminer (database management)

```
https://localhost/adminer
```

Fill in the login form as follows:

| Field | Value |
|---|---|
| System | MySQL |
| Server | mariadb |
| Username | as defined in `.env` (or root) |
| Password | as defined in `.env` |
| Database | wordpress |

### Portainer (Docker management)

```
https://localhost/portainer
```

On first visit, Portainer will ask you to create an admin account. Once logged in, you can browse containers, images, volumes, and networks through the visual interface.

### cAdvisor (container monitoring)

```
https://localhost/cadvisor
```

No login required. Displays real-time CPU, memory, network, and disk usage for each running container.

### FTP (file access)

Connect using any FTP client (e.g. FileZilla) or from the terminal:

```bash
ftp localhost
```

Log in with the FTP credentials defined in your `.env` file. You will land directly inside the WordPress files directory (`/var/www/html`).

> FTP uses passive mode on ports 21100–21110. Make sure these are not blocked by a firewall.

---

## Credentials

All credentials are stored in the `.env` file located at:
```
srcs/.env
```

> This file is never committed to version control. Keep it safe and do not share it.

### What the `.env` file contains

```bash
# MariaDB
MYSQL_HOST=                # network location of mariadb server
MYSQL_ROOT_PASSWORD=       # root password for the database
MYSQL_DATABASE=            # name of the WordPress database
MYSQL_USER=                # WordPress database user
MYSQL_PASSWORD=            # WordPress database user password

# WordPress
WORDPRESS_URL=             # site URL (https://localhost)
WORDPRESS_TITLE=           # site title
WORDPRESS_ADMIN_USER=      # WordPress admin username
WORDPRESS_ADMIN_PASSWORD=  # WordPress admin password
WORDPRESS_ADMIN_EMAIL=     # WordPress admin email
WORDPRESS_USER=            # WordPress normal-user username
WORDPRESS_USER_EMAIL=      # WordPress normal-user email
WORDPRESS_USER_PASSWORD=   # WordPress normal-user password


# FTP
FTP_USER=                  # FTP username
FTP_PASSWORD=              # FTP password
```

### Where each credential is used

| Credential | Used by |
|---|---|
| `MYSQL_ROOT_PASSWORD` | MariaDB root access, Adminer (root login) |
| `MYSQL_USER` / `MYSQL_PASSWORD` | WordPress ↔ MariaDB connection, Adminer (user login) |
| `WORDPRESS_ADMIN_USER` / `WORDPRESS_ADMIN_PASSWORD` | WordPress `/wp-admin` dashboard |
| `FTP_USER` / `FTP_PASSWORD` | FTP server login |

---

## Checking That Services Are Running

### Quick status overview

```bash
docker ps
```

All containers should have a status of `Up`. You should see:

```
nginx-container
wordpress-container
mariadb-container
redis-container
ftp-container
adminer-container
static_site-container
portainer-container
cadvisor-container
```

### Check logs for a specific service

```bash
docker logs <container-name>
```

For example:
```bash
docker logs nginx-container
docker logs mariadb-container
docker logs wordpress-container
```

### Check that the database is reachable

Exec into the WordPress container and test the connection:
```bash
docker exec -it wordpress-container bash
mariadb -h mariadb -u wp_user -p
# enter MYSQL_PASSWORD when prompted
# you should get a MariaDB prompt
```

### Check that Redis is working

```bash
docker exec -it wordpress-container bash
wp redis status --allow-root --path=/var/www/html
# should show: Status: Connected
```

### Check that NGINX is routing correctly

```bash
docker exec -it nginx-container nginx -t
# should show: syntax is ok / test is successful
```

### Visual monitoring

For a live overview of all container resource usage, visit:
```
https://localhost/cadvisor
```

For managing and inspecting containers visually, visit:
```
https://localhost/portainer
```