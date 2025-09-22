# Electra Django Server Makefile
# Development and production build targets

# Variables
DJANGO_DIR = electra_server
COMPOSE_FILE = docker-compose.django.yml
DEV_SETTINGS = electra_server.settings.dev
PROD_SETTINGS = electra_server.settings.prod

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build up down migrate createsuperuser test clean logs shell collectstatic seed

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Electra Django Server - Available Commands:"
	@echo "==========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Build Docker containers
	@echo "$(YELLOW)Building Electra Django Server...$(NC)"
	docker-compose -f $(COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)Build completed!$(NC)"

up: ## Start all services in detached mode
	@echo "$(YELLOW)Starting Electra Django Server...$(NC)"
	docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Services started! Django server: http://localhost:8001$(NC)"

down: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Services stopped!$(NC)"

restart: down up ## Restart all services

migrate: ## Run Django migrations
	@echo "$(YELLOW)Running Django migrations...$(NC)"
	cd $(DJANGO_DIR) && python manage.py migrate --settings=$(DEV_SETTINGS)
	@echo "$(GREEN)Migrations completed!$(NC)"

migrate-prod: ## Run Django migrations in production mode
	@echo "$(YELLOW)Running Django migrations (production)...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec web python manage.py migrate --noinput
	@echo "$(GREEN)Production migrations completed!$(NC)"

makemigrations: ## Create new Django migrations
	@echo "$(YELLOW)Creating Django migrations...$(NC)"
	cd $(DJANGO_DIR) && python manage.py makemigrations --settings=$(DEV_SETTINGS)
	@echo "$(GREEN)Migrations created!$(NC)"

createsuperuser: ## Create Django superuser
	@echo "$(YELLOW)Creating Django superuser...$(NC)"
	cd $(DJANGO_DIR) && python manage.py createsuperuser --settings=$(DEV_SETTINGS)

createsuperuser-prod: ## Create Django superuser in production
	@echo "$(YELLOW)Creating Django superuser (production)...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec web python manage.py createsuperuser

seed: ## Seed database with initial data
	@echo "$(YELLOW)Seeding database...$(NC)"
	cd $(DJANGO_DIR) && python manage.py seed_initial_data --settings=$(DEV_SETTINGS)
	@echo "$(GREEN)Database seeded!$(NC)"

seed-prod: ## Seed database in production
	@echo "$(YELLOW)Seeding database (production)...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec web python manage.py seed_initial_data
	@echo "$(GREEN)Production database seeded!$(NC)"

test: ## Run tests
	@echo "$(YELLOW)Running tests...$(NC)"
	cd $(DJANGO_DIR) && python manage.py test --settings=$(DEV_SETTINGS) --verbosity=2
	@echo "$(GREEN)Tests completed!$(NC)"

test-coverage: ## Run tests with coverage
	@echo "$(YELLOW)Running tests with coverage...$(NC)"
	cd $(DJANGO_DIR) && coverage run --source='.' manage.py test --settings=$(DEV_SETTINGS)
	cd $(DJANGO_DIR) && coverage report
	cd $(DJANGO_DIR) && coverage html
	@echo "$(GREEN)Coverage report generated in htmlcov/$(NC)"

pytest: ## Run pytest tests
	@echo "$(YELLOW)Running pytest...$(NC)"
	cd $(DJANGO_DIR) && pytest -v --tb=short
	@echo "$(GREEN)Pytest completed!$(NC)"

pytest-docker: ## Run pytest in Docker
	@echo "$(YELLOW)Running pytest in Docker...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec web pytest -v --tb=short
	@echo "$(GREEN)Docker pytest completed!$(NC)"

collectstatic: ## Collect static files
	@echo "$(YELLOW)Collecting static files...$(NC)"
	cd $(DJANGO_DIR) && python manage.py collectstatic --noinput --settings=$(DEV_SETTINGS)
	@echo "$(GREEN)Static files collected!$(NC)"

shell: ## Open Django shell
	@echo "$(YELLOW)Opening Django shell...$(NC)"
	cd $(DJANGO_DIR) && python manage.py shell --settings=$(DEV_SETTINGS)

shell-prod: ## Open Django shell in production
	@echo "$(YELLOW)Opening Django shell (production)...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec web python manage.py shell

dbshell: ## Open database shell
	@echo "$(YELLOW)Opening database shell...$(NC)"
	cd $(DJANGO_DIR) && python manage.py dbshell --settings=$(DEV_SETTINGS)

logs: ## Show Docker logs
	docker-compose -f $(COMPOSE_FILE) logs -f

logs-web: ## Show web container logs
	docker-compose -f $(COMPOSE_FILE) logs -f web

logs-db: ## Show database container logs
	docker-compose -f $(COMPOSE_FILE) logs -f db

clean: ## Clean up Docker containers and volumes
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	docker-compose -f $(COMPOSE_FILE) down -v
	docker-compose -f $(COMPOSE_FILE) rm -f
	docker volume prune -f
	@echo "$(GREEN)Cleanup completed!$(NC)"

reset-db: ## Reset database (WARNING: destroys all data)
	@echo "$(RED)WARNING: This will destroy all data!$(NC)"
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "\n$(YELLOW)Resetting database...$(NC)"; \
		docker-compose -f $(COMPOSE_FILE) down -v; \
		docker-compose -f $(COMPOSE_FILE) up -d db; \
		sleep 10; \
		$(MAKE) migrate-prod; \
		$(MAKE) seed-prod; \
		echo "$(GREEN)Database reset completed!$(NC)"; \
	else \
		echo "\nOperation cancelled."; \
	fi

install-deps: ## Install Python dependencies
	@echo "$(YELLOW)Installing Python dependencies...$(NC)"
	cd $(DJANGO_DIR) && pip install -r requirements.txt
	@echo "$(GREEN)Dependencies installed!$(NC)"

dev-setup: install-deps migrate seed ## Setup development environment
	@echo "$(GREEN)Development environment setup completed!$(NC)"
	@echo "Run 'make runserver' to start the development server"

runserver: ## Run Django development server
	@echo "$(YELLOW)Starting Django development server...$(NC)"
	cd $(DJANGO_DIR) && python manage.py runserver 8000 --settings=$(DEV_SETTINGS)

generate-keys: ## Generate RSA keys for digital signatures
	@echo "$(YELLOW)Generating RSA keys...$(NC)"
	cd $(DJANGO_DIR) && python scripts/generate_rsa_keys.py
	@echo "$(GREEN)RSA keys generated in keys/ directory$(NC)"

check: ## Run Django system checks
	@echo "$(YELLOW)Running Django system checks...$(NC)"
	cd $(DJANGO_DIR) && python manage.py check --settings=$(DEV_SETTINGS)
	@echo "$(GREEN)System check completed!$(NC)"

format: ## Format code with black
	@echo "$(YELLOW)Formatting code with black...$(NC)"
	cd $(DJANGO_DIR) && black . --exclude migrations
	@echo "$(GREEN)Code formatting completed!$(NC)"

lint: ## Run linting with flake8
	@echo "$(YELLOW)Running flake8 linting...$(NC)"
	cd $(DJANGO_DIR) && flake8 . --exclude migrations,venv,env
	@echo "$(GREEN)Linting completed!$(NC)"

security-check: ## Run security checks
	@echo "$(YELLOW)Running security checks...$(NC)"
	cd $(DJANGO_DIR) && python manage.py check --deploy --settings=$(PROD_SETTINGS)
	@echo "$(GREEN)Security check completed!$(NC)"

backup-db: ## Backup database
	@echo "$(YELLOW)Backing up database...$(NC)"
	docker-compose -f $(COMPOSE_FILE) exec -T db pg_dump -U electra_user electra_server > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Database backup completed!$(NC)"

status: ## Show service status
	@echo "$(YELLOW)Service Status:$(NC)"
	docker-compose -f $(COMPOSE_FILE) ps