release: cd backend && python manage.py migrate && python manage.py collectstatic --noinput
web: cd backend && gunicorn backend.wsgi:application --bind 0.0.0.0:$PORT
