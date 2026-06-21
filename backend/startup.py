#!/usr/bin/env python
import os
import sys
import subprocess
import time

# We're already in the backend directory, so no need to chdir
print("Starting Origence application...")
print(f"Working directory: {os.getcwd()}")
print(f"Python path: {sys.executable}")
print(f"Python version: {sys.version}")

# Print environment variables for debugging
print("\nEnvironment variables:")
print(f"  PORT: {os.environ.get('PORT', '8000')}")
print(f"  DEBUG: {os.environ.get('DEBUG', 'False')}")
print(f"  DATABASE_URL: {'SET' if os.environ.get('DATABASE_URL') else 'NOT SET'}")
print(f"  SECRET_KEY: {'SET' if os.environ.get('SECRET_KEY') else 'NOT SET'}")

# Try to run migrations with retries
print("\nAttempting database migrations...")
for i in range(1, 6):
    try:
        result = subprocess.run(
            [sys.executable, 'manage.py', 'migrate', '--noinput'],
            capture_output=True,
            timeout=30,
            text=True
        )
        if result.returncode == 0:
            print("✓ Migrations successful!")
            break
        else:
            print(f"✗ Attempt {i} failed:")
            if result.stdout:
                print(f"  stdout: {result.stdout[:200]}")
            if result.stderr:
                print(f"  stderr: {result.stderr[:200]}")
            if i < 5:
                print(f"  Waiting 5 seconds before retry...")
                time.sleep(5)
            else:
                print("⚠ Migrations failed after 5 attempts. Continuing anyway...")
    except Exception as e:
        print(f"✗ Attempt {i} error: {e}")
        if i < 5:
            time.sleep(5)

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
    except Exception as e:
        if i < 5:
            print(f"✗ Attempt {i} failed: {e}. Waiting 5 seconds...")
            time.sleep(5)
        else:
            print(f"⚠ Migrations failed after 5 attempts: {e}. Continuing anyway...")

# Collect static files
print("Collecting static files...")
try:
    subprocess.run(
        [sys.executable, 'manage.py', 'collectstatic', '--noinput'],
        capture_output=True,
        timeout=60
    )
    print("✓ Static files collected")
except Exception as e:
    print(f"⚠ Static files collection failed: {e}")

# Start Gunicorn
print("Starting Gunicorn server...")
port = os.environ.get('PORT', '8000')
os.execvp(sys.executable, [
    sys.executable, '-m', 'gunicorn',
    'config.wsgi:application',
    '--bind', f'0.0.0.0:{port}',
    '--workers', '3',
    '--timeout', '120'
])
