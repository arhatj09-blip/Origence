# Origence Selenium Testing - Windows PowerShell Quick Start

## ✅ Setup Complete!

All dependencies are installed. You're ready to run tests.

---

## 🚀 Quick Start (Windows PowerShell Commands)

### 1. Activate Virtual Environment (if not already active)
```powershell
# Navigate to backend directory
cd d:\PBL_project\origence\backend

# Activate venv
.venv\Scripts\Activate.ps1
```

**Output should show**: `(.venv) PS D:\PBL_project\origence\backend>`

### 2. Verify Packages (Windows PowerShell way)
```powershell
# List installed packages
pip list

# Or search for specific packages
pip show selenium
pip show pytest
pip show webdriver-manager
```

**Expected output**:
```
Name: selenium
Version: 4.43.0
Summary: Python bindings for Selenium
```

---

## 🎯 Running Tests

### Terminal 1: Start Backend Server
```powershell
cd d:\PBL_project\origence\backend
python manage.py runserver
# Runs on http://localhost:8000
```

### Terminal 2: Start Flutter Web (in new PowerShell)
```powershell
cd d:\PBL_project\origence\frontend
flutter run -d chrome
# Runs on http://localhost:3000 or similar
```

### Terminal 3: Run Tests (in new PowerShell)
```powershell
cd d:\PBL_project\origence\backend

# Activate venv first
.venv\Scripts\Activate.ps1

# Run quick start tests
pytest tests\test_quick_start.py -v -s

# Run all tests
pytest tests\ -v

# Run with HTML report
pytest tests\ -v --html=report.html --self-contained-html
```

---

## 📖 Test Files Available

Location: `d:\PBL_project\origence\backend\tests\`

| File | Purpose | Run Command |
|------|---------|-------------|
| `test_quick_start.py` | ⭐ Start here - Basic smoke tests | `pytest tests\test_quick_start.py -v` |
| `conftest.py` | Shared fixtures (browser, test data) | (Not run directly) |
| `README.md` | Test documentation | (Read in editor) |
| `__init__.py` | Package marker | (Not run directly) |

---

## 📊 Useful PowerShell Commands for Testing

### Show installed packages
```powershell
pip list
```

### Search for specific package
```powershell
pip show selenium
```

### Check Python version
```powershell
python --version
```

### Check virtual environment
```powershell
Get-Command python
# Should show: D:\PBL_project\origence\backend\.venv\Scripts\python.exe
```

### Run specific test
```powershell
# Run specific test file
pytest tests\test_quick_start.py -v

# Run specific test class
pytest tests\test_quick_start.py::TestLogin -v

# Run specific test method
pytest tests\test_quick_start.py::TestLogin::test_login_page_loads -v
```

### Run with more options
```powershell
# Verbose + show print statements
pytest tests\test_quick_start.py -v -s

# Stop on first failure
pytest tests\test_quick_start.py -v -x

# Show last failed tests
pytest tests\test_quick_start.py -v --lf

# Generate HTML report
pytest tests\ -v --html=report.html --self-contained-html

# Run with timeout (30 seconds per test)
pytest tests\ -v --timeout=30
```

---

## 🎨 Expected Output

When you run tests, you should see something like:

```
tests\test_quick_start.py::TestBasicUI::test_login_page_loads PASSED [ 10%]
tests\test_quick_start.py::TestBasicUI::test_login_form_elements_exist PASSED [ 20%]
tests\test_quick_start.py::TestBasicUI::test_create_account_link_visible PASSED [ 30%]
tests\test_quick_start.py::TestRegistration::test_navigate_to_registration_page PASSED [ 40%]
tests\test_quick_start.py::TestRegistration::test_registration_form_has_role_options PASSED [ 50%]
tests\test_quick_start.py::TestRegistration::test_student_registration PASSED [ 60%]
tests\test_quick_start.py::TestRegistration::test_faculty_registration PASSED [ 70%]
tests\test_quick_start.py::TestLogin::test_login_with_student_account PASSED [ 80%]
tests\test_quick_start.py::TestLogin::test_login_with_faculty_account PASSED [ 90%]

========================== 9 passed in 24.56s ==========================
```

---

## 🐛 Troubleshooting on Windows

### Issue: "pip is not recognized"
**Solution**: Activate virtual environment first
```powershell
.venv\Scripts\Activate.ps1
pip list  # Should work now
```

### Issue: "grep: The term 'grep' is not recognized"
**Explanation**: `grep` is Linux command. On Windows, use:
```powershell
# Instead of: pip list | grep selenium
# Use:
pip list | findstr selenium
```

### Issue: "touch is not recognized"
**Explanation**: `touch` is Linux command. On Windows, files are created automatically:
```powershell
# No need to create empty files - VS Code does it
# Or use PowerShell to create files:
New-Item -Path "tests\new_test.py" -ItemType File
```

### Issue: Chrome browser doesn't open
**Solution**: Make sure webdriver-manager is installed
```powershell
pip show webdriver-manager
# Should show version 4.0.2 or higher
```

### Issue: Tests timeout or fail
**Solution**: Make sure backend is running
```powershell
# In Terminal 1:
cd d:\PBL_project\origence\backend
python manage.py runserver
# Should show: Starting development server at http://127.0.0.1:8000/
```

---

## 📋 Complete Setup Checklist

- [ ] Python venv activated: `.venv\Scripts\Activate.ps1`
- [ ] Selenium installed: `pip show selenium`
- [ ] Pytest installed: `pip show pytest`
- [ ] WebDriver Manager installed: `pip show webdriver-manager`
- [ ] Backend running: `python manage.py runserver`
- [ ] Frontend running: `flutter run -d chrome`
- [ ] Test files exist: `Get-ChildItem tests\`
- [ ] Run quick test: `pytest tests\test_quick_start.py -v`

---

## 🎓 Next Steps

1. ✅ Activate venv: `.venv\Scripts\Activate.ps1`
2. ✅ Start backend: `python manage.py runserver`
3. ✅ Start frontend: `flutter run -d chrome`
4. ✅ Run tests: `pytest tests\test_quick_start.py -v -s`
5. ✅ View results and learn from the test output
6. ✅ Write your own tests

---

**Happy Testing on Windows! 🚀**
