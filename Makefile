COMPOSE = docker compose --env-file ./.env -f srcs/docker-compose.yml

DATA_DIR = /home/$(USER)/data

all: up

prepare:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

build:
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --rmi local --volumes --remove-orphans

re: fclean
	$(MAKE) all

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

.PHONY: all prepare build up down clean fclean re stop start