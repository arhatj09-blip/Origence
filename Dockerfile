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
RUN pip install --no-cache-dir -r requirements.txt

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create startup script
RUN printf '#!/bin/bash\nset -e\ncd /app\necho "Running migrations..."\npython manage.py migrate --noinput\necho "Collecting static files..."\npython manage.py collectstatic --noinput 2>/dev/null || true\necho "Starting Gunicorn..."\nexec gunicorn backend.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120\n' > /app/startup.sh && \
    chmod +x /app/startup.sh

EXPOSE ${PORT:-8000}

CMD ["/app/startup.sh"]
