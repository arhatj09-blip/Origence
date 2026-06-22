#!/usr/bin/env python
import os
import sys
import subprocess
import time

print("Starting Origence application...")
print(f"Working directory: {os.getcwd()}")
print(f"Python path: {sys.executable}")
print(f"Python version: {sys.version}")

# Print environment variables for debugging
print("\nEnvironment variables:")
print(f"  PORT: {os.environ.get('PORT', '8000')}")
print(f"  DEBUG: {os.environ.get('DEBUG', 'False')}")
print(f"  DATABASE_URL: {'SET (begins with ' + os.environ.get('DATABASE_URL')[:15] + '...)' if os.environ.get('DATABASE_URL') else 'NOT SET'}")
print(f"  SECRET_KEY: {'SET' if os.environ.get('SECRET_KEY') else 'NOT SET'}")

# Try to run migrations with retries
print("\nAttempting database migrations...")
migrations_ok = False
for i in range(1, 6):
    try:
        print(f"Migration attempt {i}/5...")
        result = subprocess.run(
            [sys.executable, 'manage.py', 'migrate', '--noinput'],
            capture_output=True,
            timeout=30,
            text=True
        )
        if result.returncode == 0:
            print("✓ Migrations successful!")
            migrations_ok = True
            break
        else:
            print(f"✗ Attempt {i} failed:")
            if result.stdout:
                print(f"  stdout: {result.stdout}")
            if result.stderr:
                print(f"  stderr: {result.stderr}")
            if i < 5:
                print("  Waiting 5 seconds before retry...")
                time.sleep(5)
    except Exception as e:
        print(f"✗ Attempt {i} error: {e}")
        if i < 5:
            time.sleep(5)

if not migrations_ok:
    print("⚠ WARNING: Database migrations failed after 5 attempts. Gunicorn will still start so the container remains healthy.")

# Create superuser if env variables exist
if os.environ.get("DJANGO_SUPERUSER_USERNAME") and os.environ.get("DJANGO_SUPERUSER_PASSWORD"):
    print("\nChecking for superuser creation...")
    try:
        shell_command = (
            "from django.contrib.auth import get_user_model; "
            "User = get_user_model(); "
            "import os; "
            "u = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin'); "
            "p = os.environ.get('DJANGO_SUPERUSER_PASSWORD', ''); "
            "e = os.environ.get('DJANGO_SUPERUSER_EMAIL', ''); "
            "User.objects.filter(username=u).exists() or User.objects.create_superuser(u, e, p); "
            "print('Superuser ready.')"
        )
        result = subprocess.run(
            [sys.executable, 'manage.py', 'shell', '-c', shell_command],
            capture_output=True,
            timeout=30,
            text=True
        )
        if result.returncode == 0:
            print("✓ Superuser setup: success")
        else:
            print(f"⚠ Superuser setup failed: {result.stderr[:200]}")
    except Exception as e:
        print(f"⚠ Superuser setup error: {e}")

# Collect static files
print("\nCollecting static files...")
try:
    result = subprocess.run(
        [sys.executable, 'manage.py', 'collectstatic', '--noinput'],
        capture_output=True,
        timeout=60,
        text=True
    )
    if result.returncode == 0:
        print("✓ Static files collected")
    else:
        print(f"⚠ Static files collection failed: {result.stderr[:200]}")
except Exception as e:
    print(f"⚠ Static files collection error: {e}")

# Start Gunicorn
print("\nStarting Gunicorn server...")
port = os.environ.get('PORT', '8000')
print(f"Listening on 0.0.0.0:{port}")
try:
    os.execvp(sys.executable, [
        sys.executable, '-m', 'gunicorn',
        'config.wsgi:application',
        '--bind', f'0.0.0.0:{port}',
        '--workers', '3',
        '--timeout', '120',
        '--access-logfile', '-',
        '--error-logfile', '-'
    ])
except Exception as e:
    print(f"✗ Failed to start Gunicorn: {e}")
    sys.exit(1)
