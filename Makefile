COMPOSE = docker compose -f srcs/docker-compose.yml
DB_VOLUME = /home/mait-all/data/mariadb
WP_VOLUME = /home/mait-all/data/wordpress

all: up

up:
	sudo mkdir -p $(DB_VOLUME)
	sudo mkdir -p $(WP_VOLUME)
	$(COMPOSE) up -d

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs

clean:
	$(COMPOSE) down -v --remove-orphans

fclean: clean
	docker system prune -af
	sudo rm -rf /home/mait-all/data

re: fclean build up

.PHONY: all build up down logs clean fclean re


