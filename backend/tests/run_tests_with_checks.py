"""
Smart test runner that checks if services are running before executing tests
"""

import subprocess
import requests
import time
import sys
from pathlib import Path

def check_service(url, service_name, timeout=5):
    """Check if a service is running"""
    try:
        response = requests.head(url, timeout=timeout)
        print(f"✅ {service_name} is running on {url}")
        return True
    except requests.exceptions.ConnectionError:
        print(f"❌ {service_name} is NOT running on {url}")
        return False
    except Exception as e:
        print(f"⚠️  Error checking {service_name}: {e}")
        return False

def main():
    print("="*70)
    print("ORIGENCE TEST RUNNER - Service Check")
    print("="*70)
    print()
    
    # Check backend
    print("Checking services...")
    backend_ok = check_service("http://localhost:8000", "Backend (Django)")
    frontend_ok = check_service("http://localhost:3000", "Frontend (Flutter)")
    
    print()
    
    if not backend_ok:
        print("❌ ERROR: Backend is not running!")
        print()
        print("Start backend in Terminal 1:")
        print("  cd d:\\PBL_project\\origence\\backend")
        print("  .venv\\Scripts\\Activate.ps1")
        print("  python manage.py runserver")
        print()
        return 1
    
    if not frontend_ok:
        print("❌ ERROR: Frontend is not running!")
        print()
        print("Start frontend in Terminal 2:")
        print("  cd d:\\PBL_project\\origence\\frontend")
        print("  flutter run -d chrome")
        print()
        print("Make sure you see Chrome open with Origence login page!")
        print()
        return 1
    
    print("✅ All services are running!")
    print()
    print("="*70)
    print("Running tests...")
    print("="*70)
    print()
    
    # Run pytest
    result = subprocess.run(
        ["pytest", "tests\\test_quick_start.py", "-v", "-s"],
        cwd=Path(__file__).parent.parent
    )
    
    return result.returncode

if __name__ == "__main__":
    sys.exit(main())
