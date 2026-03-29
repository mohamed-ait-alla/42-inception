COMPOSE = sudo docker compose -f srcs/docker-compose.yml


all: up

up:
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
	sudo docker system prune -af

re: fclean build up

.PHONY: all build up down logs clean fclean re


