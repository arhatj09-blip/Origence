FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc/* \
    && rm -rf /usr/share/man/*

COPY backend/requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt


COPY backend/manage.py /app/
COPY backend/startup.py /app/
COPY backend/config /app/config/
COPY backend/api /app/api/
COPY backend/auth_api /app/auth_api/
COPY backend/core /app/core/

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

CMD ["python", "startup.py"]
