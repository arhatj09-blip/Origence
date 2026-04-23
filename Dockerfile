FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/*

COPY backend/requirements.txt /app/
COPY backend/manage.py /app/
COPY backend/config /app/config/
COPY backend/api /app/api/
COPY backend/auth_api /app/auth_api/
COPY backend/core /app/core/

RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN printf '#!/bin/bash\n\
set -e\n\
cd /app\n\
echo "Running migrations..."\n\
python manage.py migrate --noinput\n\
echo "Creating superuser if not exists..."\n\
python manage.py shell -c "\n\
from django.contrib.auth import get_user_model;\n\
User = get_user_model();\n\
import os;\n\
u = os.environ.get(\"DJANGO_SUPERUSER_USERNAME\", \"admin\");\n\
p = os.environ.get(\"DJANGO_SUPERUSER_PASSWORD\", \"\");\n\
e = os.environ.get(\"DJANGO_SUPERUSER_EMAIL\", \"\");\n\
User.objects.filter(username=u).exists() or User.objects.create_superuser(u, e, p);\n\
print(\"Superuser ready.\")\n\
" 2>/dev/null || true\n\
echo "Collecting static files..."\n\
python manage.py collectstatic --noinput 2>/dev/null || true\n\
echo "Starting Gunicorn..."\n\
exec gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120\n\
' > /app/startup.sh && chmod +x /app/startup.sh

EXPOSE ${PORT:-8000}

CMD ["/app/startup.sh"]
