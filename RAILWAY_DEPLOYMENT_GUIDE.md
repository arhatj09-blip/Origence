# Railway.app Deployment Guide for Origence Project

## Prerequisites
- GitHub account
- Railway.app account (free)
- Your project pushed to GitHub

## Step 1: Prepare Your Local Code

### 1.1 Update Dependencies
Run these commands in your backend directory:

```bash
cd backend
pip install gunicorn whitenoise dj-database-url python-decouple psycopg2-binary
pip freeze > requirements.txt
```

### 1.2 Verify Files Created
Check that these files exist in your `backend/` directory:
- ✅ `Procfile` - Already created
- ✅ `runtime.txt` - Already created  
- ✅ `.railwayignore` - Already created
- ✅ `requirements.txt` - Already updated
- ✅ `backend/settings.py` - Already updated

### 1.3 Create .env File (Local Development)
Create `backend/.env`:
```
SECRET_KEY=your-secret-key-here-change-this
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,127.0.0.1:8000
```

### 1.4 Test Locally
```bash
# Install python-decouple locally if not done
pip install python-decouple

# Run migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Test server
python manage.py runserver
```

## Step 2: Push to GitHub

```bash
# From project root
git add -A
git commit -m "Prepare for Railway deployment"
git push origin main
```

## Step 3: Deploy on Railway.app

### 3.1 Sign Up & Login
1. Go to https://railway.app
2. Click "Login with GitHub"
3. Authorize Railway to access your GitHub

### 3.2 Create New Project
1. Click "New Project"
2. Click "Deploy from GitHub repo"
3. Select your `origence` repository
4. Click "Deploy"

**Railway will detect Django and start deployment automatically!**

### 3.3 Add PostgreSQL Database
1. In Railway dashboard, click "Add Plugin" (or "+")
2. Search for and select "PostgreSQL"
3. Click "Add"
4. Railway automatically sets `DATABASE_URL` environment variable

### 3.4 Set Environment Variables
1. Go to your Railway project dashboard
2. Click "Variables" tab
3. Add these variables:

```
SECRET_KEY=your-very-secure-random-string-here
DEBUG=False
ALLOWED_HOSTS=your-project.railway.app,*.railway.app
```

⚠️ **Generate a strong SECRET_KEY:**
Open Python and run:
```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```
Copy that output and paste as SECRET_KEY value.

### 3.5 Wait for Deployment
- Railway will automatically deploy your code
- You'll see logs in the "Logs" tab
- Wait for "Railway deployed successfully" message

### 3.6 Run Migrations
Once deployed:
1. Click "Connect" (top right of your web service)
2. Click your Railway project name
3. Click "Logs"
4. You should see migration ran automatically

If migrations didn't run automatically:
1. Click on your web service
2. Go to "Deploy" → "Redeploy"
3. Or run in Railway CLI:
```bash
railway run python manage.py migrate
```

### 3.7 Create Admin User (Optional)
```bash
# Using Railway CLI
railway run python manage.py createsuperuser
```

Or manually:
1. Connect to Railway PostgreSQL
2. Create user through Django admin panel once deployed

## Step 4: Get Your Live URL

1. In Railway dashboard, click on your web service
2. Click "Settings"
3. Find "Domain" section
4. Copy your URL: `https://your-project-xxxxx.railway.app`
5. This is your live API endpoint!

## Step 5: Update Flutter App

Update your Flutter app's `api_service.dart` to use Railway URL:

```dart
// Change this:
// static const String baseUrl = 'http://localhost:8000/api';

// To this:
static const String baseUrl = 'https://your-project-xxxxx.railway.app/api';
```

## Monitoring & Maintenance

### View Logs
```
Railway Dashboard → Your Project → Logs
```

### Monitor Performance
```
Railway Dashboard → Your Project → Metrics
```

### Redeploy on Code Changes
Simply push to GitHub - Railway auto-redeploys!

### Access Admin Panel
```
https://your-project-xxxxx.railway.app/admin
```

## Troubleshooting

### "502 Bad Gateway" Error
**Solution:**
1. Check logs: Railway Dashboard → Logs
2. Usually means migration failed
3. Redeploy and check migration logs

### Static Files Not Loading
```bash
# SSH into Railway and run:
railway run python manage.py collectstatic --noinput
```

### Database Connection Error
1. Verify PostgreSQL plugin was added
2. Check `DATABASE_URL` in Variables tab
3. Redeploy after adding database

### CORS Issues with Flutter
Add to Django settings:
```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://localhost:3000",
    "https://your-flutter-deployed-domain.com",
]
```

## Faculty Handover Guide

When you hand over to faculty:

1. **Share these credentials:**
   - Railway login (they create their own account)
   - GitHub repository link
   - Admin panel URL: `https://your-project.railway.app/admin`

2. **They can:**
   - View logs and metrics in Railway dashboard
   - Redeploy if code changes
   - Manage users in admin panel
   - Monitor database

3. **For any changes:**
   - Push code to GitHub
   - Railway auto-deploys
   - No manual deployment needed!

## Cost Breakdown

**Estimated monthly cost:**
- Django app: $5-10 (depending on usage)
- PostgreSQL database: $10-15
- **Total: ~$15-25/month for production**

Railway has a free tier to start - no card required for first $5 credit!

## Questions?

- Railway Docs: https://docs.railway.app
- Django Deployment: https://docs.djangoproject.com/en/4.0/howto/deployment/
