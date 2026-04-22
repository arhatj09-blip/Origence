FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Create a startup script
RUN echo '#!/bin/bash\n\
set -e\n\
cd backend\n\
echo "Running migrations..."\n\
python manage.py migrate\n\
echo "Collecting static files..."\n\
python manage.py collectstatic --noinput\n\
echo "Starting Gunicorn..."\n\
gunicorn backend.wsgi:application --bind 0.0.0.0:$PORT' > /app/startup.sh && \
chmod +x /app/startup.sh

EXPOSE $PORT

CMD ["/app/startup.sh"]
