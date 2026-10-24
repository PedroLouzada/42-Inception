COMPOSE = docker compose --env-file ./.env -f srcs/docker-compose.yml

DATA_DIR = /home/pbongiov/data

SECRETS_DIR := secrets

SECRET_FILES := \
	$(SECRETS_DIR)/db_password.txt \
	$(SECRETS_DIR)/db_root_password.txt \
	$(SECRETS_DIR)/wp_admin_password.txt \
	$(SECRETS_DIR)/wp_user_password.txt

all: up

prepare:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

secrets:
	@mkdir -p "$(SECRETS_DIR)"
	@chmod 700 "$(SECRETS_DIR)"
	@umask 077; \
	for file in $(SECRET_FILES); do \
		if [ ! -s "$$file" ]; then \
			openssl rand -hex 24 > "$$file"; \
			echo "Created $$file"; \
		else \
			echo "Keeping existing $$file"; \
		fi; \
		chmod 600 "$$file"; \
	done

build:
	$(COMPOSE) build

up: secrets prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down --rmi local --volumes --remove-orphans

re: down
	$(MAKE) all

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

ps:
	$(COMPOSE) ps

.PHONY: all prepare build up down clean fclean re stop start ps secrets