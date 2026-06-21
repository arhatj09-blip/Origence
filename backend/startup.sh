#!/bin/bash
set -e

echo "Starting Origence application..."

# Try to run migrations with retries
echo "Attempting database migrations..."
for i in 1 2 3 4 5; do
    if python manage.py migrate --noinput 2>/dev/null; then
        echo "Migrations successful!"
        break
    else
        if [ $i -lt 5 ]; then
            echo "Attempt $i failed. Waiting for database... (retrying in 5 seconds)"
            sleep 5
        else
            echo "Migrations failed after 5 attempts. Continuing anyway..."
        fi
    fi
done

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput 2>/dev/null || true

# Start Gunicorn
echo "Starting Gunicorn server..."
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120
