# Makefile for Electra Server

.PHONY: help build up down logs shell migrate createsuperuser seed test clean format lint check-env generate-keys

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Environment setup
check-env: ## Check if .env file exists
	@if [ ! -f .env ]; then \
		echo "⚠️  .env file not found. Creating from .env.example..."; \
		cp .env.example .env; \
		echo "📝 Please edit .env file with your actual configuration"; \
	else \
		echo "✅ .env file exists"; \
	fi

generate-keys: ## Generate RSA keys for JWT signing
	@echo "🔐 Generating RSA keys..."
	python scripts/generate_rsa_keys.py --key-size 4096
	@echo "✅ RSA keys generated successfully"

# Docker operations
build: check-env ## Build Docker images
	@echo "🏗️  Building Docker images..."
	docker-compose build
	@echo "✅ Docker images built successfully"

up: check-env ## Start development environment
	@echo "🚀 Starting development environment..."
	docker-compose up -d
	@echo "✅ Development environment started"
	@echo "🌐 Web application: http://localhost:8000"
	@echo "🗄️  Database: localhost:5432"
	@echo "🔴 Redis: localhost:6379"

up-prod: check-env generate-keys ## Start production environment
	@echo "🚀 Starting production environment..."
	docker-compose --profile production up -d
	@echo "✅ Production environment started"
	@echo "🌐 Web application: http://localhost:80"

down: ## Stop all services
	@echo "🛑 Stopping all services..."
	docker-compose down
	@echo "✅ All services stopped"

down-prod: ## Stop production services
	@echo "🛑 Stopping production services..."
	docker-compose --profile production down
	@echo "✅ Production services stopped"

logs: ## Show application logs
	docker-compose logs -f web

logs-prod: ## Show production logs
	docker-compose logs -f web-prod

shell: ## Open shell in web container
	docker-compose exec web bash

shell-prod: ## Open shell in production web container
	docker-compose exec web-prod bash

# Database operations
migrate: ## Run database migrations
	@echo "📊 Running database migrations..."
	docker-compose exec web python manage.py migrate
	@echo "✅ Database migrations completed"

makemigrations: ## Create new database migrations
	@echo "📊 Creating database migrations..."
	docker-compose exec web python manage.py makemigrations
	@echo "✅ Database migrations created"

createsuperuser: ## Create Django superuser
	@echo "👤 Creating superuser..."
	docker-compose exec web python manage.py createsuperuser
	@echo "✅ Superuser created"

seed: ## Seed initial development data
	@echo "🌱 Seeding initial data..."
	docker-compose exec web python manage.py seed_initial_data
	@echo "✅ Initial data seeded"

dbshell: ## Open database shell
	docker-compose exec web python manage.py dbshell

# Testing
test: ## Run tests
	@echo "🧪 Running tests..."
	docker-compose exec web python -m pytest --cov=apps --cov-report=html --cov-report=term
	@echo "✅ Tests completed"

test-local: ## Run tests locally (without Docker)
	@echo "🧪 Running tests locally..."
	python -m pytest --cov=apps --cov-report=html --cov-report=term
	@echo "✅ Tests completed"

# Code quality
format: ## Format code with black and isort
	@echo "🎨 Formatting code..."
	black .
	isort .
	@echo "✅ Code formatted"

lint: ## Run linting with flake8
	@echo "🔍 Running linters..."
	flake8 --max-line-length=100 --exclude=venv,migrations .
	@echo "✅ Linting completed"

# Development setup
setup-dev: check-env build generate-keys up migrate seed ## Complete development setup
	@echo "🎉 Development environment setup completed!"
	@echo "🌐 Application is running at: http://localhost:8000"
	@echo "📋 API Health Check: http://localhost:8000/api/health/"
	@echo "🔐 Admin Panel: http://localhost:8000/admin/"
	@echo "📚 API Documentation: http://localhost:8000/api/docs/ (if implemented)"

setup-prod: check-env build generate-keys up-prod migrate seed ## Complete production setup
	@echo "🎉 Production environment setup completed!"
	@echo "🌐 Application is running at: http://localhost"

# Maintenance
clean: ## Clean up Docker resources
	@echo "🧹 Cleaning up..."
	docker-compose down -v --remove-orphans
	docker system prune -f
	@echo "✅ Cleanup completed"

backup-db: ## Backup database
	@echo "💾 Creating database backup..."
	mkdir -p backups
	docker-compose exec -T db pg_dump -U postgres electra_db > backups/backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Database backup created in backups/"

restore-db: ## Restore database from backup (usage: make restore-db BACKUP=backup_file.sql)
	@if [ -z "$(BACKUP)" ]; then \
		echo "❌ Please specify backup file: make restore-db BACKUP=backup_file.sql"; \
		exit 1; \
	fi
	@echo "📂 Restoring database from $(BACKUP)..."
	docker-compose exec -T db psql -U postgres -d electra_db < $(BACKUP)
	@echo "✅ Database restored"

# Security
security-check: ## Run security checks
	@echo "🔒 Running security checks..."
	safety check
	bandit -r apps/
	@echo "✅ Security checks completed"

# Local development (without Docker)
install-local: check-env ## Install dependencies locally
	@echo "📦 Installing local dependencies..."
	python -m venv venv
	. venv/bin/activate && pip install -r requirements.txt
	@echo "✅ Local dependencies installed"

run-local: ## Run Django development server locally
	@echo "🚀 Starting local development server..."
	. venv/bin/activate && python manage.py runserver
	
migrate-local: ## Run migrations locally
	@echo "📊 Running local migrations..."
	. venv/bin/activate && python manage.py migrate

# Information
status: ## Show status of all services
	@echo "📊 Service status:"
	docker-compose ps

info: ## Show system information
	@echo "ℹ️  System Information:"
	@echo "Docker version:"
	@docker --version
	@echo "Docker Compose version:"
	@docker-compose --version
	@echo "Python version:"
	@python --version || echo "Python not found in PATH"