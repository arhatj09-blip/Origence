FROM python:3.11-slim

WORKDIR /app

# Install only essential runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/*

# Copy only backend directory
COPY backend/requirements.txt /app/
COPY backend/manage.py /app/
COPY backend/backend /app/backend/
COPY backend/api /app/api/
COPY backend/auth_api /app/auth_api/
COPY backend/core /app/core/

# Install Python dependencies without cache
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# Set environment for HuggingFace - don't download models during build
ENV HF_HUB_DISABLE_TELEMETRY=1 \
    HF_HOME=/tmp/hf_cache \
    TRANSFORMERS_CACHE=/tmp/transformers_cache \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create startup script that handles everything
RUN echo '#!/bin/bash\n\
set -e\n\
cd /app\n\
echo "Running migrations..."\n\
python manage.py migrate --noinput\n\
echo "Collecting static files..."\n\
python manage.py collectstatic --noinput 2>/dev/null || true\n\
echo "Starting Gunicorn..."\n\
exec gunicorn backend.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120' > /app/startup.sh && \
chmod +x /app/startup.sh

EXPOSE ${PORT:-8000}

CMD ["/app/startup.sh"]
