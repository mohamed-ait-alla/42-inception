# Developer Documentation — Inception

This document is intended for developers who want to set up, build, and manage the Inception infrastructure from scratch.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Configuration Files](#configuration-files)
- [Build and Launch](#build-and-launch)
- [Managing Containers and Volumes](#managing-containers-and-volumes)
- [Data Storage and Persistence](#data-storage-and-persistence)

---

## Prerequisites

Make sure the following tools are installed on your machine before starting:

| Tool | Minimum Version | Purpose |
|---|---|---|
| Docker Engine | 20.10+ | Container runtime |
| Docker Compose | v2.0+ | Multi-container orchestration |
| make | any | Build automation |


Install on Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose make
sudo usermod -aG docker $USER  # allow running docker without sudo
newgrp docker
```

Verify installation:
```bash
# Check Docker installation
docker --version
docker-compose --version

# Check make installation
make --version

# Verify Docker daemon is running
docker ps
```

---

## Project Structure

```
inception/
├── srcs/
│    ├── .env                          # environment variables (not committed)
│    ├── docker-compose.yml
│    └── requirements/
│        ├── nginx/
│        │   ├── Dockerfile
│        │   ├── .dockerignore
│        │   └── conf/
│        │       └── nginx.conf
│        ├── wordpress/
│        │   ├── Dockerfile
│        │   └── tools/
│        │       └── entrypoint.sh
│        ├── mariadb/
│        │   ├── Dockerfile
│        │   ├── .dockerignore
│        │   ├── conf/
│        │   │   └── 50-server.cnf
│        │   └── tools/
│        │       └── init.sh
│        └── bonus/
│            ├── redis/
│            │   └── Dockerfile
│            ├── ftp/
│            │   ├── Dockerfile
│            │   ├── conf/
│            │   │   └── vsftpd.conf
│            │   └── tools/
│            │       └── entrypoint.sh
│            ├── static-site/
│            │   ├── Dockerfile
│            │   ├── conf/
│            │   │   └── nginx.conf
│            │   └── website/
│            │       └── index.html
│            ├── adminer/
│            │   └── Dockerfile
│            ├── portainer/
│            │   └── Dockerfile
│            └── cadvisor/
│                └── Dockerfile
├── .gitignore
├── Makefile
├── DEV_DOC.md
├── USER_DOC.md
└── README.md
```

---

## Environment Setup

### 1. Clone the repository

```bash
git clone https://github.com/Mohamed-ait-alla/42-inception.git inception
cd inception
```

### 2. Create the `.env` file

The `.env` file must be created manually at `srcs/.env`. It is never committed to version control.

```bash
touch srcs/.env
```

Fill it with the following variables:

```bash
# ── MariaDB ────────────────────────────────────────
MYSQL_HOST=mariadb
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_wp_password

# ── WordPress ──────────────────────────────────────
WORDPRESS_URL=https://localhost
WORDPRESS_TITLE=My WordPress Site
WORDPRESS_ADMIN_USER=admin
WORDPRESS_ADMIN_PASSWORD=your_admin_password
WORDPRESS_ADMIN_EMAIL=admin@example.com
WORDPRESS_USER=editor
WORDPRESS_USER_PASSWORD=your_editor_password
WORDPRESS_USER_EMAIL=editor@example.com

# ── FTP ────────────────────────────────────────────
FTP_USER=your_ftp_user
FTP_PASSWORD=your_ftp_password
```

> Never use weak passwords. MariaDB and WordPress passwords must be strong — they are injected directly into running services at container startup.

### 3. Create host data directories

The Makefile handles this automatically, but you can also do it manually:

```bash
mkdir -p /home/mait-all/data/mariadb
mkdir -p /home/mait-all/data/wordpress
mkdir -p /home/mait-all/data/portainer
```

These directories are bind-mounted by Docker named volumes to persist database and WordPress data across container restarts.

---

## Configuration Files

### NGINX — `nginx.conf`

Handles TLS termination and routing:
- Port 443, TLS 1.2/1.3 only
- Forwards `.php` requests to WordPress via FastCGI on port 9000
- Reverse proxies `/adminer`, `/portainer`, `/cadvisor` to their respective containers

### MariaDB — `50-server.cnf`

Key setting:
```ini
[mysqld]
bind-address = 0.0.0.0  # accept connections from all container interfaces
port         = 3306     # mariadb traffic via 3306 default port
```

### vsftpd — `vsftpd.conf`

Key settings:
```ini
pasv_enable=YES             # enable passive mode
pasv_min_port=21100         # passive mode ports
pasv_max_port=21110
chroot_local_user=YES       # chroot user to their home directory (/var/www/html)
local_root=/var/www/html    # point FTP root to /var/www/html
```

---

## Build and Launch

### Makefile targets

| Target | Description |
|---|---|
| `make` | Creates data dirs, builds all images, starts all containers |
| `make down` | Stops all containers (data is preserved) |
| `make clean` | Stops containers and removes them |
| `make fclean` | Full cleanup — removes containers, images, volumes, and host data |
| `make re` | `fclean` + full rebuild from scratch |

### Under the hood

`make` runs:
```bash
mkdir -p /home/mait-all/data/mariadb
mkdir -p /home/mait-all/data/wordpress
mkdir -p /home/mait-all/data/portainer
docker compose -f srcs/docker-compose.yml up -d
```

### Build a single service

```bash
docker compose -f srcs/docker-compose.yml build <service>
# example:
docker compose -f srcs/docker-compose.yml build wordpress
```

### Start with live logs

```bash
docker compose -f srcs/docker-compose.yml up --build
# without -d, so logs stream to your terminal
```

---

## Managing Containers and Volumes

### Container management

```bash
# List all running containers
docker ps

# List all containers including stopped ones
docker ps -a

# View logs of a specific container
docker logs <container-name>

# Follow logs in real time
docker logs -f <container-name>

# Exec into a running container
docker exec -it <container-name> bash

# Restart a single service
docker compose -f srcs/docker-compose.yml restart <service>

# Rebuild and restart a single service
docker compose -f srcs/docker-compose.yml up -d --build <service>
```

### Volume management

```bash
# List all Docker volumes
docker volume ls

# Inspect a volume (shows mountpoint and config)
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_portainer_data

# Remove a specific volume (container must be stopped first)
docker volume rm srcs_mariadb_data

# Remove all unused volumes
docker volume prune
```

### Network management

```bash
# List all Docker networks
docker network ls

# Inspect the inception network
docker network inspect srcs_inception

# Check which containers are connected to it
docker network inspect srcs_inception --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Useful one-liners

```bash
# Check MariaDB connection from WordPress container
docker exec -it wordpress-container mariadb -h mariadb -u wp_user -p

# Check Redis status from WordPress container
docker exec -it wordpress-container wp redis status --allow-root --path=/var/www/html

# Test NGINX config without restarting
docker exec -it nginx-container nginx -t

# Reload NGINX config (no downtime)
docker exec -it nginx-container nginx -s reload

# Check MariaDB users and hosts
docker exec -it mariadb-container mariadb -u root -p -e "SELECT user, host FROM mysql.user;"
```

---

## Data Storage and Persistence

### Where data lives

All persistent data is stored on the host machine under:

```
/home/mait-all/data/
├── mariadb/      # MariaDB database files
├── wordpress/    # WordPress core files, themes, plugins, uploads
└── portainer/    # portainer files
```

### How persistence works

The named volumes in `docker-compose.yml` use `driver_opts` to bind to these host paths:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mait-all/data/mariadb

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mait-all/data/wordpress
```

This means:
- If you run `make down` and `make` again — **data is preserved**
- If you run `make fclean` — **data is deleted** along with the host directories
- The MariaDB container reads and writes directly to `/home/mait-all/data/mariadb` on your host
- The WordPress and FTP containers share the same `wordpress_data` volume, so both access the same files

### Persistence flow

```
docker compose up
      ↓
Docker mounts /home/mait-all/data/mariadb   → mariadb container /var/lib/mysql
Docker mounts /home/mait-all/data/wordpress → wordpress container /var/www/html
                                            → ftp container /var/www/html (same volume)
      ↓
MariaDB initializes only if /var/lib/mysql is empty (first run)
WordPress installs only if wp-config.php does not exist (first run)
      ↓
docker compose down
      ↓
Containers stop — data stays on host at /home/mait-all/data/
      ↓
docker compose up again
      ↓
Containers start — existing data is reused, no re-initialization
```