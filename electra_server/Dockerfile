# Electra Django Server Dockerfile
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_SETTINGS_MODULE=electra_server.settings.prod

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
        netcat-traditional \
        git \
        openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create app directory and user
RUN groupadd -r electra && useradd -r -g electra electra
WORKDIR /app

# Copy requirements first for better caching
COPY electra_server/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY electra_server/ .

# Create necessary directories
RUN mkdir -p /app/logs /app/keys /app/media /app/staticfiles \
    && chown -R electra:electra /app

# Switch to non-root user
USER electra

# Collect static files
RUN python manage.py collectstatic --noinput --settings=electra_server.settings.base || true

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/ || exit 1

# Default command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "electra_server.wsgi:application"]