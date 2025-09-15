#!/bin/bash

# Electra Development Setup Script
# This script sets up the development environment for Electra

set -e

echo "🗳️  Setting up Electra Development Environment"
echo "=============================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//')
if [ "$(printf '%s\n' "18.0.0" "$NODE_VERSION" | sort -V | head -n1)" != "18.0.0" ]; then
    echo "❌ Node.js version $NODE_VERSION is too old. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Node.js $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed."
    exit 1
fi

NPM_VERSION=$(npm -v)
echo "✅ npm $NPM_VERSION"

# Check Docker (optional)
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker -v | cut -d' ' -f3 | sed 's/,//')
    echo "✅ Docker $DOCKER_VERSION"
    HAS_DOCKER=true
else
    echo "⚠️  Docker not found (optional for development)"
    HAS_DOCKER=false
fi

# Check PostgreSQL (if not using Docker)
if [ "$HAS_DOCKER" = false ]; then
    if ! command -v psql &> /dev/null; then
        echo "❌ PostgreSQL is not installed and Docker is not available."
        echo "   Please install PostgreSQL 12+ or Docker."
        exit 1
    fi
    POSTGRES_VERSION=$(psql --version | awk '{print $3}' | sed 's/\..*//')
    echo "✅ PostgreSQL $POSTGRES_VERSION"
fi

echo ""
echo "🚀 Starting setup process..."

# Setup backend
echo "📦 Setting up backend..."
cd server

if [ ! -f package.json ]; then
    echo "❌ Backend package.json not found. Run this script from the project root."
    exit 1
fi

echo "   Installing dependencies..."
npm install

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "   Creating .env file..."
    cp .env.example .env
    echo "   ⚠️  Please edit server/.env with your configuration!"
fi

# Generate RSA keys if they don't exist
if [ ! -f keys/private.pem ] || [ ! -f keys/public.pem ]; then
    echo "   Generating RSA keys..."
    npm run keys:generate
fi

echo "   ✅ Backend setup complete"

cd ..

# Setup database
echo "💾 Setting up database..."

if [ "$HAS_DOCKER" = true ]; then
    echo "   Starting database with Docker..."
    docker-compose -f docker-compose.dev.yml up -d postgres
    
    # Wait for database to be ready
    echo "   Waiting for database to be ready..."
    sleep 5
    
    # Check if database is ready
    until docker-compose -f docker-compose.dev.yml exec postgres pg_isready -U electra_user; do
        echo "   Database is starting up..."
        sleep 2
    done
    
    echo "   ✅ Database is ready"
else
    echo "   Please ensure PostgreSQL is running and create a database named 'electra_dev'"
    echo "   with user 'electra_user' and password 'electra_password'"
fi

# Check Flutter (optional for backend development)
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n1 | awk '{print $2}')
    echo "✅ Flutter $FLUTTER_VERSION found"
    
    echo "📱 Setting up frontend..."
    cd client
    
    if [ -f pubspec.yaml ]; then
        echo "   Installing Flutter dependencies..."
        flutter pub get
        echo "   ✅ Frontend setup complete"
    else
        echo "   ⚠️  Flutter project not found in client/ directory"
    fi
    
    cd ..
else
    echo "⚠️  Flutter not found (optional for backend development)"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit server/.env with your configuration"
echo "   2. Start the backend: cd server && npm run dev"
if [ "$HAS_DOCKER" = true ]; then
    echo "   3. View database: http://localhost:8080 (Adminer)"
fi
if command -v flutter &> /dev/null && [ -f client/pubspec.yaml ]; then
    echo "   4. Start the frontend: cd client && flutter run -d web"
fi
echo ""
echo "📚 Documentation: See README.md for more details"
echo "🐛 Issues: Report issues at https://github.com/RS12A/electra/issues"