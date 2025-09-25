# Multi-stage Dockerfile for Django application

# Stage 1: Base Python image with system dependencies
FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
        netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Create app user (non-root for security)
RUN groupadd -r electra && useradd -r -g electra electra

# Set work directory
WORKDIR /app

# Stage 2: Dependencies
FROM base as dependencies

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 3: Development
FROM dependencies as development

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p logs media staticfiles keys \
    && chown -R electra:electra /app

# Switch to non-root user
USER electra

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/ || exit 1

# Default command for development
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# Stage 4: Production
FROM dependencies as production

# Install gunicorn for production
RUN pip install gunicorn==21.2.0

# Copy application code
COPY . .

# Create necessary directories with proper permissions
RUN mkdir -p logs media staticfiles keys \
    && chown -R electra:electra /app

# Collect static files
RUN python manage.py collectstatic --noinput --settings=electra_server.settings.prod

# Switch to non-root user
USER electra

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/ || exit 1

# Production command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--worker-class", "gthread", "--threads", "2", "electra_server.wsgi:application"]