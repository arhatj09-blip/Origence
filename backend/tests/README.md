# Origence Test Suite
## Quick Start Guide

---

## 🚀 QUICK START (5 minutes)

### 1. Install Test Dependencies
```bash
cd backend
pip install -r requirements-test.txt
```

### 2. Start Backend Server (Terminal 1)
```bash
cd backend
python manage.py runserver
# Runs on http://localhost:8000
```

### 3. Start Frontend (Terminal 2)
```bash
cd frontend
flutter run -d chrome
# Runs on http://localhost:3000 (or similar, check console)
```

### 4. Run Tests (Terminal 3)
```bash
cd backend

# Run quick start tests (simplest, good for learning)
pytest tests/test_quick_start.py -v

# Run all tests
pytest tests/ -v

# Run with HTML report
pytest tests/ -v --html=report.html

# Run specific test class
pytest tests/test_quick_start.py::TestLogin -v

# Run specific test
pytest tests/test_quick_start.py::TestLogin::test_login_with_student_account -v
```

---

## 📁 TEST FILES

### `conftest.py` (Fixtures)
Provides common test fixtures:
- `browser` - Chrome WebDriver instance
- `wait` - WebDriverWait for explicit waits
- `test_user` - Test student credentials
- `test_faculty` - Test faculty credentials
- `test_batch` - Test batch data
- `base_url` - Frontend URL
- `api_url` - Backend API URL

### `test_quick_start.py` ⭐ (START HERE)
Basic smoke tests to verify:
- Login page loads
- Registration works
- Login works
- Form elements exist

**Run with**: `pytest tests/test_quick_start.py -v -s`

### `test_api.py`
Backend API tests:
- Authentication (register, login, logout)
- Batch management (create, join, update threshold)
- Document operations (upload, retrieve)

**Run with**: `pytest tests/test_api.py -v`

### `test_frontend.py`
Frontend UI tests using Selenium:
- Login/registration UI
- Dashboard functionality
- Batch management UI
- Document upload UI

**Run with**: `pytest tests/test_frontend.py -v`

### `test_workflows.py`
End-to-end workflow tests:
- Complete faculty → student → upload flow
- Multi-user scenarios
- Full application lifecycle

**Run with**: `pytest tests/test_workflows.py -v`

---

## 🎯 RECOMMENDED TEST ORDER

1. **Start with API Tests** (faster feedback)
   ```bash
   pytest tests/test_api.py -v
   ```

2. **Then UI Tests** (after API working)
   ```bash
   pytest tests/test_frontend.py -v
   ```

3. **Finally E2E Tests** (full workflows)
   ```bash
   pytest tests/test_workflows.py -v
   ```

4. **Run All Tests**
   ```bash
   pytest tests/ -v --html=report.html
   ```

---

## 📊 COMMON PYTEST COMMANDS

```bash
# Run with verbose output
pytest tests/ -v

# Run with detailed print statements
pytest tests/ -v -s

# Run specific test file
pytest tests/test_quick_start.py -v

# Run specific test class
pytest tests/test_quick_start.py::TestLogin -v

# Run specific test
pytest tests/test_quick_start.py::TestLogin::test_login_with_student_account -v

# Run and generate HTML report
pytest tests/ -v --html=report.html --self-contained-html

# Run with coverage report
pytest tests/ --cov=api --cov=auth_api --cov-report=html

# Run with timeout (30 seconds per test)
pytest tests/ --timeout=30

# Run only marked tests
pytest tests/ -m smoke
pytest tests/ -m "not slow"

# Run in parallel (4 workers)
pytest tests/ -n 4

# Run until first failure
pytest tests/ -x

# Run last failed tests only
pytest tests/ --lf

# Run with detailed traceback
pytest tests/ -v --tb=long
```

---

## 🔍 TROUBLESHOOTING

### Test Fails: "Connection refused"
**Problem**: Backend not running
```bash
# Solution: Start backend in separate terminal
cd backend
python manage.py runserver
```

### Test Fails: "No such element"
**Problem**: Element selector wrong or page not loaded
```python
# Solution: Use explicit waits instead of implicit
wait.until(EC.presence_of_element_located((By.ID, "element")))
```

### Test Fails: "Timeout waiting for element"
**Problem**: Element takes time to load
```python
# Solution: Increase wait time in conftest.py
wait = WebDriverWait(browser, 20)  # Increase from 10 to 20 seconds
```

### Tests Pass Locally but Fail in CI
**Problem**: Different environment or timing issues
```bash
# Run with headless mode (for CI/CD)
# In conftest.py, uncomment:
# options.add_argument("--headless")

# Add extra sleep time
pytest tests/ --timeout=60
```

### Browser Not Opening
**Problem**: ChromeDriver not found
```bash
# Solution: Reinstall webdriver-manager
pip install --upgrade webdriver-manager
pytest tests/ -v
```

### Test Flakiness (Sometimes Passes, Sometimes Fails)
**Problem**: Implicit waits or timing issues
```python
# Solution: Use explicit waits
wait = WebDriverWait(browser, 15)
wait.until(EC.element_to_be_clickable((By.ID, "button")))
button.click()
```

---

## 📝 WRITING YOUR OWN TESTS

### Template for New Test
```python
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC

@pytest.mark.smoke  # Mark as smoke test (fast, critical)
class TestMyFeature:
    """Test description"""
    
    def test_something(self, browser, wait, test_user):
        """Test description"""
        # Arrange
        browser.get("http://localhost:3000")
        
        # Act
        element = browser.find_element(By.NAME, "field")
        element.send_keys("test data")
        button = browser.find_element(By.XPATH, "//button[contains(text(), 'Submit')]")
        button.click()
        
        # Assert
        success_message = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'success')]"))
        )
        assert success_message.is_displayed()
```

### Best Practices
```python
# ✅ GOOD: Use explicit waits
wait.until(EC.element_to_be_clickable((By.ID, "button"))).click()

# ❌ BAD: Use implicit sleep
import time; time.sleep(5)

# ✅ GOOD: Use IDs or names for locators
element = browser.find_element(By.ID, "submit")

# ❌ BAD: Use fragile XPath
element = browser.find_element(By.XPATH, "//div[contains(...)]/button")

# ✅ GOOD: Clear fields before typing
field.clear()
field.send_keys("new value")

# ❌ BAD: Don't clear
field.send_keys("new value")  # Appends to existing
```

---

## 🎓 LEARNING RESOURCES

- [Selenium Python Docs](https://selenium-python.readthedocs.io/)
- [Pytest Docs](https://docs.pytest.org/)
- [Selenium Best Practices](https://www.selenium.dev/documentation/test_practices/)

---

## 🚀 NEXT STEPS

1. ✅ Install dependencies: `pip install -r requirements-test.txt`
2. ✅ Run quick start tests: `pytest tests/test_quick_start.py -v`
3. ✅ Run API tests: `pytest tests/test_api.py -v`
4. ✅ Run UI tests: `pytest tests/test_frontend.py -v`
5. ✅ Write your own tests using the template
6. ✅ Generate HTML reports: `pytest tests/ --html=report.html`
7. ✅ Integrate with CI/CD (GitHub Actions, etc.)

---

**Happy Testing! 🎉**
