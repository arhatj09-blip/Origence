#!/usr/bin/env python
import os
import sys
import subprocess
import time

# Change to backend directory
os.chdir(os.path.join(os.path.dirname(__file__), '..', 'backend'))

print("Starting Origence application...")
print(f"Working directory: {os.getcwd()}")

# Try to run migrations with retries
print("Attempting database migrations...")
for i in range(1, 6):
    try:
        result = subprocess.run(
            [sys.executable, 'manage.py', 'migrate', '--noinput'],
            capture_output=True,
            timeout=30
        )
        if result.returncode == 0:
            print("✓ Migrations successful!")
            break
        else:
            if i < 5:
                print(f"✗ Attempt {i} failed. Waiting 5 seconds...")
                time.sleep(5)
            else:
                print("⚠ Migrations failed after 5 attempts. Continuing anyway...")
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
