"""
Verification Script for Origence Test Setup
Run this to verify all testing tools are installed and working
"""

import sys
import subprocess

def check_package(package_name, import_name=None):
    """Check if a package is installed"""
    if import_name is None:
        import_name = package_name
    
    try:
        __import__(import_name)
        print(f"✅ {package_name} is installed")
        return True
    except ImportError:
        print(f"❌ {package_name} is NOT installed")
        return False

def check_command(command):
    """Check if a command is available"""
    try:
        result = subprocess.run(
            [command, "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print(f"✅ {command} is available")
            return True
    except:
        pass
    print(f"❌ {command} is NOT available")
    return False

def main():
    print("=" * 60)
    print("ORIGENCE TEST SETUP VERIFICATION")
    print("=" * 60)
    print()
    
    print("1. Checking Python Packages:")
    print("-" * 60)
    
    packages = [
        ("selenium", "selenium"),
        ("pytest", "pytest"),
        ("pytest-html", "pytest_html"),
        ("pytest-timeout", "pytest_timeout"),
        ("webdriver-manager", "webdriver_manager"),
        ("requests", "requests"),
    ]
    
    all_packages_ok = True
    for package_name, import_name in packages:
        if not check_package(package_name, import_name):
            all_packages_ok = False
    
    print()
    print("2. Checking System Commands:")
    print("-" * 60)
    
    commands = ["python", "pip"]
    all_commands_ok = True
    for cmd in commands:
        if not check_command(cmd):
            all_commands_ok = False
    
    print()
    print("3. Checking Test Files:")
    print("-" * 60)
    
    import os
    test_files = [
        "conftest.py",
        "test_quick_start.py",
        "README.md",
        "__init__.py",
    ]
    
    all_files_ok = True
    test_dir = os.path.dirname(os.path.abspath(__file__))
    
    for test_file in test_files:
        file_path = os.path.join(test_dir, test_file)
        if os.path.exists(file_path):
            print(f"✅ {test_file} exists")
        else:
            print(f"❌ {test_file} NOT found")
            all_files_ok = False
    
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    
    if all_packages_ok and all_commands_ok and all_files_ok:
        print("✅ All checks passed! Setup is complete.")
        print()
        print("Next steps:")
        print("1. Start backend: python manage.py runserver")
        print("2. Start frontend: flutter run -d chrome")
        print("3. Run tests: pytest tests\\test_quick_start.py -v")
        return 0
    else:
        print("⚠️  Some checks failed. Please install missing packages:")
        print()
        print("pip install selenium pytest pytest-html pytest-timeout webdriver-manager")
        return 1

if __name__ == "__main__":
    sys.exit(main())
