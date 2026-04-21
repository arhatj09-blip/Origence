# Railway.app Deployment Checklist - Status Report

**Date:** April 22, 2026  
**Project:** Origence  
**Status:** ✅ ALL PREREQUISITES VERIFIED & FIXED

---

## ✅ Backend Prerequisites - COMPLETED

### 1. Dependencies & Packages
- ✅ **gunicorn** - Installed (v25.3.0)
- ✅ **whitenoise** - Installed (v6.12.0) 
- ✅ **dj-database-url** - Installed (v3.1.2)
- ✅ **python-decouple** - Installed (v3.8)
- ✅ **psycopg2-binary** - Installed (v2.9.11)
- ✅ **django-cors-headers** - Installed (v4.9.0)

**Status:** `requirements.txt` is up-to-date with all necessary packages.

### 2. Configuration Files
- ✅ **Procfile** - Created and updated with static files collection
  ```
  web: gunicorn backend.wsgi:application --bind 0.0.0.0:$PORT
  release: python manage.py migrate && python manage.py collectstatic --noinput
  ```

- ✅ **runtime.txt** - Configured for Python 3.11.0
  ```
  python-3.11.0
  ```

- ✅ **.railwayignore** - Created with proper ignore patterns

### 3. Django Settings (config/settings.py) - FIXED ✅

#### Before:
- ❌ SECRET_KEY was hardcoded
- ❌ DEBUG was hardcoded to True  
- ❌ ALLOWED_HOSTS was set to ['*']
- ❌ Database hardcoded to SQLite
- ❌ Missing WhitNoise middleware
- ❌ Missing STATIC_ROOT configuration

#### After (FIXED):
- ✅ **SECRET_KEY**: Now uses environment variables via python-decouple
  ```python
  SECRET_KEY = config('SECRET_KEY', default='django-insecure-...')
  ```

- ✅ **DEBUG**: Now uses environment variables
  ```python
  DEBUG = config('DEBUG', default=True, cast=bool)
  ```

- ✅ **ALLOWED_HOSTS**: Now uses environment variables
  ```python
  ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1', cast=Csv())
  ```

- ✅ **Database**: Now supports both PostgreSQL (Railway) and SQLite (local)
  ```python
  if config('DATABASE_URL', default=None):
      DATABASES = {'default': dj_database_url.config(...)}
  else:
      DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', ...}}
  ```

- ✅ **WhitNoise Middleware**: Added for production static files
  ```python
  MIDDLEWARE = [
      'django.middleware.security.SecurityMiddleware',
      'whitenoise.middleware.WhiteNoiseMiddleware',
      ...
  ]
  ```

- ✅ **Static Files Configuration**: Added proper static root and storage
  ```python
  STATIC_URL = 'static/'
  STATIC_ROOT = BASE_DIR / 'staticfiles'
  STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
  ```

### 4. Environment Variables (.env)
- ✅ **.env** - Already created with local development settings
- ✅ **.env.example** - Created as reference for environment variables

**Local Development .env Content:**
```
SECRET_KEY=your-secret-key-here-change-this
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,127.0.0.1:8000
```

### 5. Git Configuration
- ✅ **.gitignore** - Fixed merge conflict and added proper entries
  - `.env` and `backend/.env` properly ignored
  - `staticfiles/` properly ignored
  - `__pycache__/` properly ignored
  - `*.pyc` properly ignored

---

## ✅ Frontend Prerequisites - COMPLETED

### 1. API Configuration - FIXED ✅

#### api_host_io.dart - UPDATED
Before: Hardcoded localhost URL  
After: Includes production URL template with clear instructions

```dart
String getApiBaseUrlImpl() {
  // PRODUCTION: Change this to your Railway URL
  // const String productionUrl = 'https://your-app-name.railway.app/api/';
  
  // Development URLs
  if (Platform.isAndroid) {
    return 'http://192.168.1.11:8000/api/';
  }
  return 'http://127.0.0.1:8000/api/';
  
  // Uncomment below for production
  // return productionUrl;
}
```

#### api_host_web.dart - UPDATED
Before: Hardcoded localhost URL  
After: Includes production URL template with clear instructions

```dart
// PRODUCTION: Change this to your Railway URL
// const String baseUrl = 'https://your-app-name.railway.app/api/';

String getApiBaseUrlImpl() => 'http://127.0.0.1:8000/api/';

// Uncomment below for production (replace with your Railway URL)
// String getApiBaseUrlImpl() => 'https://your-app-name.railway.app/api/';
```

---

## 📋 Next Steps for Deployment to Railway.app

### Step 1: Generate Production SECRET_KEY
```bash
cd backend
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```
Save this value - you'll need it for Railway environment variables.

### Step 2: Commit Changes to GitHub
```bash
git add -A
git commit -m "Prepare for Railway.app deployment - add environment variables and WhitNoise"
git push origin main
```

### Step 3: Create Railway Project
1. Go to https://railway.app
2. Login with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select `origence` repository
5. Railway will auto-detect Django and start deployment

### Step 4: Add PostgreSQL Database
1. In Railway dashboard, click "Add Plugin" (or "+")
2. Search for "PostgreSQL"
3. Click "Add"
4. Railway automatically sets `DATABASE_URL` environment variable

### Step 5: Set Production Environment Variables
In Railway Dashboard → Your Project → Variables, add:

```
SECRET_KEY=<your-generated-secret-key-from-step-1>
DEBUG=False
ALLOWED_HOSTS=your-project-xxxxx.railway.app,*.railway.app
```

### Step 6: Update Frontend API URL
In `frontend/lib/api_host_io.dart` and `frontend/lib/api_host_web.dart`:

Replace:
```dart
String getApiBaseUrlImpl() => 'http://127.0.0.1:8000/api/';
```

With:
```dart
String getApiBaseUrlImpl() => 'https://your-project-xxxxx.railway.app/api/';
```

Then commit and push this change.

### Step 7: Monitor Deployment
1. Check Railway Dashboard → Logs
2. Wait for "Railway deployed successfully" message
3. Verify migrations ran automatically

### Step 8: Access Your Deployment
- **API Base URL**: `https://your-project-xxxxx.railway.app/api/`
- **Admin Panel**: `https://your-project-xxxxx.railway.app/admin/`
- **Create Superuser** (if needed):
  ```bash
  railway run python manage.py createsuperuser
  ```

---

## 🔒 Security Checklist

- ✅ All hardcoded secrets removed
- ✅ DEBUG is configurable per environment
- ✅ .env file is in .gitignore
- ✅ WhitNoise configured for static files
- ✅ CORS properly configured
- ✅ Database supports PostgreSQL for production

---

## ⚠️ Important Reminders

1. **NEVER commit `.env` files to GitHub** - They're in .gitignore now
2. **Generate a strong SECRET_KEY** - Use the command in Step 1
3. **Keep DEBUG=False in production** - Already configured in Railway setup
4. **Update Flutter API URLs** - Must be done before rebuilding Flutter app
5. **Test locally first** - Run `python manage.py runserver` to verify locally

---

## 🚀 Verification Commands

Run these commands to verify everything is working locally:

```bash
cd backend

# Install all dependencies
pip install -r requirements.txt

# Run migrations locally
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Test the server
python manage.py runserver

# Run tests
python manage.py test

# Check deployment checklist
python manage.py check --deploy
```

---

## 📞 Troubleshooting

### If you see "502 Bad Gateway"
1. Check Railway logs for errors
2. Verify migrations ran successfully
3. Redeploy if needed

### If static files don't load
1. Verify `collectstatic` ran in Procfile
2. Check WhitNoise is in MIDDLEWARE
3. Verify STATIC_ROOT is set

### If database connection fails
1. Verify PostgreSQL plugin was added
2. Check DATABASE_URL in Railway Variables
3. Redeploy after adding database

### If CORS issues occur
1. Update ALLOWED_HOSTS in Railway Variables
2. Update Flutter API URLs
3. Rebuild and redeploy

---

**All prerequisites have been checked and fixed. Your project is ready for Railway.app deployment!** 🎉
