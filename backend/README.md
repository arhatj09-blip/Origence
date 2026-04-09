# Origence Django Backend

## Setup

1. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```
2. Run migrations:
   ```sh
   python manage.py makemigrations
   python manage.py migrate
   ```
3. Start the server:
   ```sh
   python manage.py runserver
   ```

## API Endpoints
- `POST /api/register/` — Register new user
- `POST /api/login/` — Login
- `POST /api/logout/` — Logout
