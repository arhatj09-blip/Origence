# Selenium Testing Guide for Origence
## Complete Step-by-Step Tutorial

---

## 📋 TABLE OF CONTENTS
1. [Introduction to Selenium](#introduction-to-selenium)
2. [Why Selenium for Origence?](#why-selenium-for-origence)
3. [Setup & Installation](#setup--installation)
4. [Selenium Basics](#selenium-basics)
5. [Testing Strategy](#testing-strategy)
6. [Backend API Testing (with Requests)](#backend-api-testing-with-requests)
7. [Frontend Web Testing (Selenium)](#frontend-web-testing-selenium)
8. [Complete Test Suite](#complete-test-suite)
9. [Running Tests](#running-tests)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

---

## 🤔 INTRODUCTION TO SELENIUM

### What is Selenium?
Selenium is a powerful tool for **automated web browser testing**. It allows you to:
- Control a real web browser programmatically
- Click buttons, fill forms, submit data
- Navigate between pages
- Verify page content and element visibility
- Simulate user interactions

### How Selenium Works
```
Your Test Script
       ↓
Selenium WebDriver
       ↓
Browser Driver (ChromeDriver, FirefoxDriver, etc.)
       ↓
Real Web Browser (Chrome, Firefox, Safari, Edge)
       ↓
Website/Application
```

### Supported Languages
- Python (Selenium + unittest/pytest)
- Java
- C#
- Ruby
- JavaScript
- Go

**For this guide, we'll use Python** because:
- Your backend is Python/Django
- Easy to integrate with your development environment
- Great libraries for API testing too

---

## 🎯 WHY SELENIUM FOR ORIGENCE?

### What Selenium Can Test
✅ **Web Browser Interactions**
- Login/registration forms
- Dashboard navigation
- Batch creation and joining
- Document upload
- Button clicks and form validation
- Error messages

✅ **User Workflows**
- Complete faculty batch creation → student join → document upload flow
- Cross-browser compatibility
- Responsive design (if needed)

✅ **Visual Verification**
- Elements are visible/hidden correctly
- Page elements appear after actions
- Status messages display properly

### What Selenium CANNOT Test
❌ **Backend APIs Directly** (use `requests` library instead)
❌ **Mobile App** (Flutter native - needs Flutter testing tools)
❌ **Database Queries** (use Django's test framework)
❌ **Performance Testing** (use JMeter or LoadRunner)
❌ **Backend Logic** (use unit tests)

### For Origence, We'll Use:
- **Selenium**: Frontend web UI testing (Flutter web build)
- **Requests Library**: Backend API testing
- **pytest**: Test framework and runner
- **unittest**: Alternative test framework

---

## 🛠️ SETUP & INSTALLATION

### Step 1: Install Python Packages

#### In Backend Virtual Environment
```bash
cd backend
pip install selenium pytest requests pytest-html pytest-timeout
```

**Package Explanations**:
- `selenium` - Web browser automation
- `pytest` - Test framework (better than unittest)
- `requests` - HTTP library for API testing
- `pytest-html` - Generate HTML test reports
- `pytest-timeout` - Set test timeouts

#### Verify Installation
```bash
pip list | grep -E "selenium|pytest|requests"
```

---

### Step 2: Download WebDriver

Selenium needs a WebDriver to control the browser. For Chrome:

#### Option A: Using WebDriver Manager (Recommended)
```bash
pip install webdriver-manager
```

This automatically downloads and manages ChromeDriver for you.

#### Option B: Manual Download
1. Check your Chrome version: chrome://version/
2. Download matching ChromeDriver from: https://chromedriver.chromium.org/
3. Place in project: `backend/drivers/chromedriver.exe`
4. Add to PATH or reference in code

---

### Step 3: Project Structure

Create testing directory:
```bash
mkdir backend/tests
touch backend/tests/__init__.py
touch backend/tests/conftest.py
touch backend/tests/test_api.py
touch backend/tests/test_frontend.py
touch backend/tests/test_workflows.py
```

**Directory Structure**:
```
backend/
├── tests/
│   ├── __init__.py                 # Package marker
│   ├── conftest.py                 # Pytest configuration & fixtures
│   ├── test_api.py                 # Backend API tests
│   ├── test_frontend.py            # Frontend UI tests
│   ├── test_workflows.py           # Complete workflow tests
│   ├── test_auth.py                # Authentication tests
│   └── fixtures/
│       ├── test_data.py            # Test data generators
│       └── users.py                # Test user fixtures
├── manage.py
├── requirements.txt
└── ...
```

---

## 🔧 SELENIUM BASICS

### Basic Selenium Syntax

#### 1. Import and Setup
```python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

# Create WebDriver
driver = webdriver.Chrome(
    service=Service(ChromeDriverManager().install())
)

# Navigate to URL
driver.get("http://localhost:3000/")

# Close browser
driver.quit()
```

#### 2. Finding Elements

```python
from selenium.webdriver.common.by import By

# Find by ID
element = driver.find_element(By.ID, "login-button")

# Find by Name
element = driver.find_element(By.NAME, "username")

# Find by Class
element = driver.find_element(By.CLASS_NAME, "submit-btn")

# Find by CSS Selector
element = driver.find_element(By.CSS_SELECTOR, "input[type='password']")

# Find by XPath
element = driver.find_element(By.XPATH, "//button[contains(text(), 'Login')]")

# Find by Link Text
element = driver.find_element(By.LINK_TEXT, "Create Account")

# Find Multiple Elements
elements = driver.find_elements(By.CLASS_NAME, "batch-tile")
```

**Best Practices for Selectors**:
- ✅ Use ID (most reliable)
- ✅ Use Name attributes
- ✅ Use CSS selectors (specific)
- ⚠️ Use XPath (fragile, easy to break)
- ❌ Avoid selecting by text alone

#### 3. Interacting with Elements

```python
# Click button
element.click()

# Type text
element.send_keys("your text here")

# Clear text field
element.clear()

# Submit form
element.submit()

# Get text
text = element.text

# Get attribute
value = element.get_attribute("value")

# Check if displayed
is_visible = element.is_displayed()

# Check if enabled
is_enabled = element.is_enabled()

# Get element count
count = len(driver.find_elements(By.CLASS_NAME, "batch-tile"))
```

#### 4. Waiting (Very Important!)
```python
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Wait up to 10 seconds for element to be clickable
wait = WebDriverWait(driver, 10)
element = wait.until(
    EC.element_to_be_clickable((By.ID, "submit-button"))
)
element.click()

# Wait for element to be visible
wait.until(
    EC.visibility_of_element_located((By.ID, "success-message"))
)

# Wait for element to be present in DOM
wait.until(
    EC.presence_of_element_located((By.CLASS_NAME, "batch-tile"))
)

# Wait for text to be present
wait.until(
    EC.text_to_be_present_in_element((By.ID, "message"), "Success")
)

# Wait for URL to change
wait.until(EC.url_contains("/dashboard"))

# Implicit wait (global, all elements)
driver.implicitly_wait(10)  # 10 seconds
```

**⚠️ Never Use `time.sleep()`!**
```python
# BAD - wastes time
import time
time.sleep(5)

# GOOD - waits only as long as needed (max 10 seconds)
wait.until(EC.presence_of_element_located((By.ID, "element")))
```

#### 5. Multiple Tabs/Windows
```python
# Get current window handle
current_window = driver.current_window_handle

# Get all window handles
all_windows = driver.window_handles

# Switch to window
driver.switch_to.window(all_windows[1])

# Close current tab
driver.close()

# Switch back
driver.switch_to.window(current_window)
```

---

## 📊 TESTING STRATEGY

### What to Test?

#### For Origence, Test These Scenarios:

1. **Authentication** (Priority: HIGH)
   - User registration (faculty and student)
   - User login with correct credentials
   - User login with wrong credentials
   - User logout
   - Session persistence

2. **Batch Management** (Priority: HIGH)
   - Faculty creates batch
   - Faculty updates similarity threshold
   - Student joins batch with valid code
   - Student joins batch with invalid code
   - View batch details
   - Display batch member count

3. **Document Submission** (Priority: HIGH)
   - Student uploads valid PDF
   - Student uploads valid DOCX
   - Student uploads valid TXT
   - Student uploads unsupported file (error)
   - Document status is displayed (accepted/rejected)
   - Similarity score is visible

4. **Dashboard Features** (Priority: MEDIUM)
   - Dashboard loads after login
   - Batch tiles display correctly
   - Pagination works (if implemented)
   - Refresh button updates data
   - Navigation between pages works

5. **Form Validation** (Priority: MEDIUM)
   - Empty field validation
   - Invalid input detection
   - Error messages display
   - Success messages display
   - Form resets after submit

6. **Cross-Browser** (Priority: LOW)
   - Chrome
   - Firefox
   - Safari
   - Edge

### Test Pyramid
```
                    /\
                   /  \       E2E Tests (Full Workflows)
                  /    \      ↑ Few tests, slow, high value
                 /______\
                /        \
               /          \     Integration Tests (API + UI)
              /            \    ↑ Some tests, medium speed
             /              \
            /________________\
           /                  \
          /                    \   Unit Tests (Functions, Methods)
         /                      \  ↑ Many tests, fast, foundational
        /________________________\
```

**For Origence**:
- **Unit Tests** (Django): Test NLP algorithms, password hashing
- **API Tests** (pytest + requests): Test backend endpoints
- **UI Tests** (Selenium): Test frontend web interface
- **E2E Tests** (Selenium): Complete workflows

---

## 🔌 BACKEND API TESTING (WITH REQUESTS)

### Why Test APIs?

Before testing the UI, test the backend:
- Faster feedback (no browser overhead)
- Easier to debug
- Test edge cases (invalid data, missing fields)
- Automate without UI

### Setup

#### Create `backend/tests/test_api.py`

```python
import pytest
import requests
import json
from django.test import TestCase
from auth_api.models import User
from api.models import Batch, StudentBatchMapping, Document

# Base URL for API
BASE_URL = "http://localhost:8000/api"

class TestAuthAPI(TestCase):
    """Test authentication endpoints"""
    
    def setUp(self):
        """Setup test data before each test"""
        self.register_data = {
            "username": "testuser",
            "password": "TestPassword123",
            "confirm_password": "TestPassword123",
            "role": "student"
        }
    
    def test_register_success(self):
        """Test successful user registration"""
        response = requests.post(
            f"{BASE_URL}/register/",
            json=self.register_data
        )
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        assert response.json()['status'] == 'success'
        
        # Verify user created in database
        assert User.objects.filter(username="testuser").exists()
    
    def test_register_duplicate_username(self):
        """Test registration with duplicate username"""
        # Create first user
        requests.post(f"{BASE_URL}/register/", json=self.register_data)
        
        # Try to create duplicate
        response = requests.post(
            f"{BASE_URL}/register/",
            json=self.register_data
        )
        
        assert response.status_code == 400
        assert response.json()['status'] == 'error'
        assert 'username' in response.json()['errors']
    
    def test_register_password_mismatch(self):
        """Test registration with mismatched passwords"""
        data = self.register_data.copy()
        data['confirm_password'] = 'DifferentPassword'
        
        response = requests.post(f"{BASE_URL}/register/", json=data)
        
        assert response.status_code == 400
        assert 'confirm_password' in response.json()['errors']
    
    def test_login_success(self):
        """Test successful login"""
        # First register
        requests.post(f"{BASE_URL}/register/", json=self.register_data)
        
        # Then login
        login_data = {
            "username": "testuser",
            "password": "TestPassword123"
        }
        response = requests.post(f"{BASE_URL}/login/", json=login_data)
        
        assert response.status_code == 200
        assert response.json()['status'] == 'success'
        assert response.json()['username'] == 'testuser'
        assert response.json()['role'] == 'student'
    
    def test_login_invalid_credentials(self):
        """Test login with wrong password"""
        requests.post(f"{BASE_URL}/register/", json=self.register_data)
        
        login_data = {
            "username": "testuser",
            "password": "WrongPassword"
        }
        response = requests.post(f"{BASE_URL}/login/", json=login_data)
        
        assert response.status_code == 401
        assert response.json()['status'] == 'error'


class TestBatchAPI(TestCase):
    """Test batch management endpoints"""
    
    def setUp(self):
        """Create faculty user before each test"""
        # Create faculty user directly in database
        from django.contrib.auth.hashers import make_password
        self.faculty = User.objects.create(
            username='prof_smith',
            password=make_password('password123'),
            role='faculty'
        )
        
        # Create student user
        self.student = User.objects.create(
            username='john_doe',
            password=make_password('password123'),
            role='student'
        )
    
    def test_create_batch_success(self):
        """Test faculty creating a batch"""
        data = {
            "username": "prof_smith",
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "similarity_threshold": 0.75
        }
        
        response = requests.post(
            f"{BASE_URL}/create-batch/",
            json=data
        )
        
        assert response.status_code == 200
        assert response.json()['status'] == 'success'
        assert response.json()['batch']['batch_name'] == 'CS101 Spring 2024'
        
        # Verify in database
        assert Batch.objects.filter(batch_code='CS101_SPR24').exists()
    
    def test_create_batch_invalid_threshold(self):
        """Test batch creation with invalid threshold"""
        data = {
            "username": "prof_smith",
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "similarity_threshold": 1.5  # Invalid: > 1.0
        }
        
        response = requests.post(f"{BASE_URL}/create-batch/", json=data)
        
        assert response.status_code == 400
        assert 'threshold' in response.json()['message'].lower()
    
    def test_create_batch_duplicate_code(self):
        """Test creating batch with duplicate batch code"""
        data = {
            "username": "prof_smith",
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "similarity_threshold": 0.75
        }
        
        # Create first batch
        requests.post(f"{BASE_URL}/create-batch/", json=data)
        
        # Try to create with same code
        response = requests.post(f"{BASE_URL}/create-batch/", json=data)
        
        assert response.status_code == 400
        assert 'already exists' in response.json()['message']
    
    def test_join_batch_success(self):
        """Test student joining batch"""
        # Create batch first
        batch_data = {
            "username": "prof_smith",
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "similarity_threshold": 0.75
        }
        requests.post(f"{BASE_URL}/create-batch/", json=batch_data)
        
        # Student joins
        join_data = {
            "username": "john_doe",
            "batch_code": "CS101_SPR24"
        }
        response = requests.post(f"{BASE_URL}/join-batch/", json=join_data)
        
        assert response.status_code == 200
        assert response.json()['status'] == 'success'
        
        # Verify mapping created
        assert StudentBatchMapping.objects.filter(
            student__username='john_doe'
        ).exists()
    
    def test_join_batch_invalid_code(self):
        """Test joining batch with invalid code"""
        join_data = {
            "username": "john_doe",
            "batch_code": "INVALID_CODE"
        }
        response = requests.post(f"{BASE_URL}/join-batch/", json=join_data)
        
        assert response.status_code == 404
        assert 'Invalid batch code' in response.json()['message']
    
    def test_get_batches_faculty(self):
        """Test faculty retrieving their batches"""
        # Create batch
        batch_data = {
            "username": "prof_smith",
            "batch_name": "CS101 Spring 2024",
            "batch_code": "CS101_SPR24",
            "similarity_threshold": 0.75
        }
        requests.post(f"{BASE_URL}/create-batch/", json=batch_data)
        
        # Get batches
        response = requests.post(
            f"{BASE_URL}/get-batches/",
            json={"username": "prof_smith"}
        )
        
        assert response.status_code == 200
        assert len(response.json()['batches']) == 1
        assert response.json()['batches'][0]['batch_code'] == 'CS101_SPR24'


class TestDocumentAPI(TestCase):
    """Test document upload and retrieval"""
    
    def setUp(self):
        """Setup users and batch"""
        from django.contrib.auth.hashers import make_password
        
        self.faculty = User.objects.create(
            username='prof_smith',
            password=make_password('password123'),
            role='faculty'
        )
        
        self.student = User.objects.create(
            username='john_doe',
            password=make_password('password123'),
            role='student'
        )
        
        # Create batch
        self.batch = Batch.objects.create(
            batch_name='CS101',
            batch_code='CS101_SPR24',
            created_by=self.faculty,
            similarity_threshold=0.75
        )
        
        # Add student to batch
        StudentBatchMapping.objects.create(
            student=self.student,
            batch=self.batch
        )
    
    def test_upload_document_success(self):
        """Test uploading a document"""
        # Create a test PDF file
        with open('test_document.txt', 'w') as f:
            f.write("This is a test document for plagiarism checking.")
        
        with open('test_document.txt', 'rb') as f:
            files = {'file': ('test_document.txt', f, 'text/plain')}
            data = {
                'username': 'john_doe',
                'batch_id': self.batch.id
            }
            
            response = requests.post(
                f"{BASE_URL}/upload-document/",
                files=files,
                data=data
            )
        
        assert response.status_code == 200
        assert response.json()['status'] == 'success'
        assert 'document' in response.json()
```

### Running API Tests
```bash
cd backend

# Run all tests
pytest tests/

# Run specific test file
pytest tests/test_api.py

# Run specific test class
pytest tests/test_api.py::TestAuthAPI

# Run specific test
pytest tests/test_api.py::TestAuthAPI::test_register_success

# With verbose output
pytest -v tests/

# With coverage report
pytest --cov=api tests/
```

---

## 🌐 FRONTEND WEB TESTING (SELENIUM)

### Build Flutter as Web First

```bash
cd frontend
flutter build web --release
# Output in: build/web/
```

### Selenium Test Setup

#### Create `backend/tests/conftest.py`
```python
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.support.ui import WebDriverWait

@pytest.fixture(scope="session")
def browser():
    """
    Fixture to provide browser instance for all tests.
    Session scope = created once, used by all tests.
    """
    options = webdriver.ChromeOptions()
    # options.add_argument("--headless")  # Uncomment for headless mode
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=options
    )
    
    driver.implicitly_wait(10)  # 10 second implicit wait
    
    yield driver
    
    driver.quit()

@pytest.fixture
def wait(browser):
    """Fixture to provide WebDriverWait for explicit waits"""
    return WebDriverWait(browser, 10)

@pytest.fixture
def test_user():
    """Fixture providing test user credentials"""
    return {
        "username": "testuser",
        "password": "TestPassword123",
        "role": "student"
    }

@pytest.fixture
def test_faculty():
    """Fixture providing test faculty credentials"""
    return {
        "username": "testfaculty",
        "password": "FacultyPass123",
        "role": "faculty"
    }
```

---

#### Create `backend/tests/test_frontend.py`
```python
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
import time

BASE_URL = "http://localhost:3000"  # Flutter web dev server port

class TestLogin:
    """Test login functionality"""
    
    def test_login_page_loads(self, browser):
        """Verify login page loads"""
        browser.get(BASE_URL)
        
        # Check page title or key element
        title = browser.find_element(By.XPATH, "//*[contains(text(), 'Origence')]")
        assert title.is_displayed()
    
    def test_login_username_field_exists(self, browser):
        """Verify username field exists"""
        browser.get(BASE_URL)
        
        username_field = browser.find_element(By.NAME, "username")
        assert username_field.is_displayed()
    
    def test_login_password_field_exists(self, browser):
        """Verify password field exists"""
        browser.get(BASE_URL)
        
        password_field = browser.find_element(By.NAME, "password")
        assert password_field.is_displayed()
    
    def test_login_success(self, browser, wait, test_user):
        """Test successful login flow"""
        # Navigate to login page
        browser.get(BASE_URL)
        
        # Find and fill username field
        username_field = browser.find_element(By.NAME, "username")
        username_field.clear()
        username_field.send_keys(test_user["username"])
        
        # Find and fill password field
        password_field = browser.find_element(By.NAME, "password")
        password_field.clear()
        password_field.send_keys(test_user["password"])
        
        # Click login button
        login_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
        login_button.click()
        
        # Wait for navigation to dashboard
        wait.until(EC.url_contains("/dashboard"))
        
        # Verify we're on dashboard
        assert "/dashboard" in browser.current_url or "student" in browser.page_source.lower()
    
    def test_login_invalid_password(self, browser, wait):
        """Test login with invalid password"""
        browser.get(BASE_URL)
        
        username_field = browser.find_element(By.NAME, "username")
        username_field.send_keys("testuser")
        
        password_field = browser.find_element(By.NAME, "password")
        password_field.send_keys("WrongPassword")
        
        login_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
        login_button.click()
        
        # Wait for error message
        error_message = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Invalid')]"))
        )
        assert error_message.is_displayed()
    
    def test_create_account_link(self, browser, wait):
        """Test navigation to create account page"""
        browser.get(BASE_URL)
        
        # Click create account link
        create_account_link = browser.find_element(By.LINK_TEXT, "Create Account")
        create_account_link.click()
        
        # Wait for registration form
        wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Create Account')]"))
        )
        
        assert "register" in browser.current_url or "create" in browser.current_url

class TestRegistration:
    """Test user registration"""
    
    def test_register_student_success(self, browser, wait):
        """Test successful student registration"""
        browser.get(BASE_URL)
        
        # Click create account
        create_account_link = browser.find_element(By.LINK_TEXT, "Create Account")
        create_account_link.click()
        
        # Fill registration form
        username = browser.find_element(By.NAME, "username")
        username.send_keys("newstudent123")
        
        password = browser.find_element(By.NAME, "password")
        password.send_keys("SecurePass123")
        
        confirm_password = browser.find_element(By.NAME, "confirm_password")
        confirm_password.send_keys("SecurePass123")
        
        # Select student role
        student_radio = browser.find_element(By.XPATH, "//input[@value='student']")
        student_radio.click()
        
        # Click register button
        register_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Register')]")
        register_button.click()
        
        # Wait for success message or navigation
        success_message = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'success')]"))
        )
        assert success_message.is_displayed()
    
    def test_register_password_mismatch(self, browser, wait):
        """Test registration with mismatched passwords"""
        browser.get(BASE_URL)
        
        create_account_link = browser.find_element(By.LINK_TEXT, "Create Account")
        create_account_link.click()
        
        username = browser.find_element(By.NAME, "username")
        username.send_keys("newuser")
        
        password = browser.find_element(By.NAME, "password")
        password.send_keys("Password123")
        
        confirm_password = browser.find_element(By.NAME, "confirm_password")
        confirm_password.send_keys("DifferentPassword")
        
        register_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Register')]")
        register_button.click()
        
        # Wait for error message
        error_message = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'do not match')]"))
        )
        assert error_message.is_displayed()

class TestStudentDashboard:
    """Test student dashboard features"""
    
    def test_dashboard_loads_after_login(self, browser, wait, test_user):
        """Test dashboard loads after successful login"""
        browser.get(BASE_URL)
        
        # Login
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_user["username"])
        
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_user["password"])
        
        login_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
        login_button.click()
        
        # Wait for dashboard element
        dashboard = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]"))
        )
        assert dashboard.is_displayed()
    
    def test_join_batch_dialog_opens(self, browser, wait, test_user):
        """Test join batch dialog opens"""
        # Login first
        browser.get(BASE_URL)
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_user["username"])
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_user["password"])
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        # Wait for dashboard to load
        wait.until(EC.presence_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]")))
        
        # Click "Join Batch" button
        join_batch_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Join Batch')]")
        join_batch_button.click()
        
        # Wait for dialog to appear
        dialog = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Batch Code')]"))
        )
        assert dialog.is_displayed()
    
    def test_join_batch_with_code(self, browser, wait, test_user):
        """Test joining a batch with code"""
        # Login
        browser.get(BASE_URL)
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_user["username"])
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_user["password"])
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.presence_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]")))
        
        # Click join batch button
        join_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Join Batch')]")
        join_button.click()
        
        # Fill in batch code
        batch_code_input = wait.until(
            EC.presence_of_element_located((By.NAME, "batch_code"))
        )
        batch_code_input.send_keys("CS101_SPR24")
        
        # Click confirm button
        confirm_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Join')]")
        confirm_button.click()
        
        # Wait for success message
        success = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'successfully')]"))
        )
        assert success.is_displayed()
    
    def test_upload_document_button_visible(self, browser, wait, test_user):
        """Test upload document button is visible in batch"""
        # Login and join batch first
        browser.get(BASE_URL)
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_user["username"])
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_user["password"])
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.presence_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]")))
        
        # If not in batch, join first
        try:
            join_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Join Batch')]")
            join_button.click()
            batch_code = wait.until(EC.presence_of_element_located((By.NAME, "batch_code")))
            batch_code.send_keys("CS101_SPR24")
            confirm = browser.find_element(By.XPATH, "//button[contains(text(), 'Join')]")
            confirm.click()
            wait.until(EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'successfully')]")))
        except:
            pass  # Already in batch
        
        # Click on batch tile
        batch_tile = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//div[contains(text(), 'CS101')]"))
        )
        batch_tile.click()
        
        # Check for upload button
        upload_button = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Upload')]"))
        )
        assert upload_button.is_displayed()

class TestFacultyDashboard:
    """Test faculty dashboard features"""
    
    def test_create_batch_dialog_opens(self, browser, wait, test_faculty):
        """Test create batch dialog opens"""
        # Login as faculty
        browser.get(BASE_URL)
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_faculty["username"])
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_faculty["password"])
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.presence_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]")))
        
        # Click create batch button
        create_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Create Batch')]")
        create_button.click()
        
        # Wait for dialog
        dialog = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'Batch Name')]"))
        )
        assert dialog.is_displayed()
    
    def test_create_batch_success(self, browser, wait, test_faculty):
        """Test creating a batch"""
        browser.get(BASE_URL)
        username = browser.find_element(By.NAME, "username")
        username.send_keys(test_faculty["username"])
        password = browser.find_element(By.NAME, "password")
        password.send_keys(test_faculty["password"])
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.presence_of_element_located((By.XPATH, "//*[contains(text(), 'Dashboard')]")))
        
        # Click create batch
        create_button = browser.find_element(By.XPATH, "//button[contains(text(), 'Create Batch')]")
        create_button.click()
        
        # Fill form
        wait.until(EC.visibility_of_element_located((By.NAME, "batch_name")))
        
        batch_name = browser.find_element(By.NAME, "batch_name")
        batch_name.send_keys("Selenium Test Batch")
        
        batch_code = browser.find_element(By.NAME, "batch_code")
        batch_code.send_keys("SELENIUM_TEST_001")
        
        threshold = browser.find_element(By.NAME, "threshold")
        threshold.clear()
        threshold.send_keys("0.75")
        
        # Click create button
        create_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Create')]")
        create_btn.click()
        
        # Wait for success
        success = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'successfully')]"))
        )
        assert success.is_displayed()
```

---

## 📋 COMPLETE TEST SUITE

### Create `backend/tests/test_workflows.py`
```python
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC

BASE_URL = "http://localhost:3000"

class TestCompleteWorkflow:
    """End-to-end workflow tests"""
    
    def test_faculty_create_batch_student_join_upload(self, browser, wait):
        """
        Complete workflow:
        1. Faculty creates batch
        2. Student joins batch
        3. Student uploads document
        """
        # Step 1: Register and login as faculty
        browser.get(BASE_URL)
        
        # Register faculty
        create_account = browser.find_element(By.LINK_TEXT, "Create Account")
        create_account.click()
        
        username = wait.until(EC.presence_of_element_located((By.NAME, "username")))
        username.send_keys("prof_selenium_001")
        
        password = browser.find_element(By.NAME, "password")
        password.send_keys("FacultyPass123")
        
        confirm = browser.find_element(By.NAME, "confirm_password")
        confirm.send_keys("FacultyPass123")
        
        faculty_role = browser.find_element(By.XPATH, "//input[@value='faculty']")
        faculty_role.click()
        
        register_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Register')]")
        register_btn.click()
        
        wait.until(EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'success')]")))
        
        # Login as faculty
        username = browser.find_element(By.NAME, "username")
        username.send_keys("prof_selenium_001")
        password = browser.find_element(By.NAME, "password")
        password.send_keys("FacultyPass123")
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.url_contains("/dashboard"))
        
        # Step 2: Faculty creates batch
        create_batch_btn = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Create Batch')]"))
        )
        create_batch_btn.click()
        
        batch_name_input = wait.until(EC.presence_of_element_located((By.NAME, "batch_name")))
        batch_name_input.send_keys("Selenium Test Batch")
        
        batch_code_input = browser.find_element(By.NAME, "batch_code")
        batch_code_input.send_keys("SELENIUM_E2E_001")
        
        threshold_input = browser.find_element(By.NAME, "threshold")
        threshold_input.send_keys("0.75")
        
        create_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Create')]")
        create_btn.click()
        
        batch_created = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'successfully')]"))
        )
        assert batch_created.is_displayed()
        
        # Step 3: Logout faculty
        logout_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Logout')]")
        logout_btn.click()
        
        wait.until(EC.url_contains("login") or EC.presence_of_element_located((By.NAME, "username")))
        
        # Step 4: Register and login as student
        create_account = browser.find_element(By.LINK_TEXT, "Create Account")
        create_account.click()
        
        username = wait.until(EC.presence_of_element_located((By.NAME, "username")))
        username.send_keys("student_selenium_001")
        
        password = browser.find_element(By.NAME, "password")
        password.send_keys("StudentPass123")
        
        confirm = browser.find_element(By.NAME, "confirm_password")
        confirm.send_keys("StudentPass123")
        
        student_role = browser.find_element(By.XPATH, "//input[@value='student']")
        student_role.click()
        
        register_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Register')]")
        register_btn.click()
        
        wait.until(EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'success')]")))
        
        # Login as student
        username = browser.find_element(By.NAME, "username")
        username.send_keys("student_selenium_001")
        password = browser.find_element(By.NAME, "password")
        password.send_keys("StudentPass123")
        browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
        
        wait.until(EC.url_contains("/dashboard"))
        
        # Step 5: Student joins batch
        join_btn = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Join Batch')]"))
        )
        join_btn.click()
        
        batch_code_input = wait.until(EC.presence_of_element_located((By.NAME, "batch_code")))
        batch_code_input.send_keys("SELENIUM_E2E_001")
        
        confirm_btn = browser.find_element(By.XPATH, "//button[contains(text(), 'Join')]")
        confirm_btn.click()
        
        join_success = wait.until(
            EC.visibility_of_element_located((By.XPATH, "//*[contains(text(), 'successfully')]"))
        )
        assert join_success.is_displayed()
        
        # Step 6: Student clicks on batch
        batch_tile = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//div[contains(text(), 'SELENIUM_E2E_001')]"))
        )
        batch_tile.click()
        
        # Step 7: Student uploads document
        upload_btn = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Upload')]"))
        )
        upload_btn.click()
        
        # Verify upload or document status
        assert "/batch" in browser.current_url or "batch" in browser.page_source.lower()
```

---

## 🏃 RUNNING TESTS

### Start Backend Server
```bash
cd backend
python manage.py runserver
# Runs on http://localhost:8000
```

### Start Flutter Web (in different terminal)
```bash
cd frontend
flutter run -d chrome
# Runs on http://localhost:3000 (or similar)
```

### Run Selenium Tests
```bash
# Run all Selenium tests
pytest tests/test_frontend.py -v

# Run specific test class
pytest tests/test_frontend.py::TestLogin -v

# Run specific test
pytest tests/test_frontend.py::TestLogin::test_login_success -v

# Generate HTML report
pytest tests/ -v --html=report.html

# Run with headless mode (no visible browser)
# Edit conftest.py: uncomment options.add_argument("--headless")
pytest tests/ -v
```

### Run All Tests (API + Frontend)
```bash
# Run all tests with coverage
pytest tests/ -v --cov=api --cov=auth_api --html=report.html

# Run with timeout (30 seconds per test)
pytest tests/ --timeout=30

# Run with marker (if you add @pytest.mark.slow, etc.)
pytest tests/ -m "not slow"
```

---

## ✅ BEST PRACTICES

### 1. **Use Explicit Waits (Not Implicit)**
```python
# ✅ GOOD
wait = WebDriverWait(driver, 10)
element = wait.until(EC.element_to_be_clickable((By.ID, "button")))
element.click()

# ❌ BAD
import time
time.sleep(5)
element = driver.find_element(By.ID, "button")
element.click()
```

### 2. **Use Fixtures for Setup/Teardown**
```python
# ✅ GOOD
@pytest.fixture
def browser():
    driver = webdriver.Chrome(...)
    yield driver
    driver.quit()

# ❌ BAD
def test_something():
    driver = webdriver.Chrome(...)
    # test code
    driver.quit()
```

### 3. **Find Elements by ID, Name, CSS Selector (in order of preference)**
```python
# ✅ BEST: ID (unique, reliable)
element = driver.find_element(By.ID, "submit-button")

# ✅ GOOD: Name
element = driver.find_element(By.NAME, "username")

# ✅ OK: CSS Selector (specific)
element = driver.find_element(By.CSS_SELECTOR, "button.submit-primary")

# ⚠️ FRAGILE: XPath
element = driver.find_element(By.XPATH, "//button[contains(@class, 'primary')]")

# ❌ BAD: Text only
element = driver.find_element(By.LINK_TEXT, "Click Here")  # Changes easily
```

### 4. **Separate Concerns**
```python
# Create page object models
class LoginPage:
    def __init__(self, driver):
        self.driver = driver
        self.username_field = driver.find_element(By.NAME, "username")
        self.password_field = driver.find_element(By.NAME, "password")
        self.login_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
    
    def login(self, username, password):
        self.username_field.send_keys(username)
        self.password_field.send_keys(password)
        self.login_button.click()

# Usage
login_page = LoginPage(driver)
login_page.login("user", "pass")
```

### 5. **Handle Exceptions Gracefully**
```python
from selenium.common.exceptions import TimeoutException, NoSuchElementException

try:
    element = wait.until(EC.presence_of_element_located((By.ID, "element")))
except TimeoutException:
    print("Element not found within timeout period")
    driver.save_screenshot("error.png")
    raise

try:
    element = driver.find_element(By.ID, "element")
except NoSuchElementException:
    print("Element doesn't exist")
```

### 6. **Take Screenshots on Failure**
```python
@pytest.fixture(autouse=True)
def screenshot_on_failure(browser, request):
    yield
    if request.node.rep_call.failed:
        browser.save_screenshot(f"screenshots/{request.node.name}.png")
```

### 7. **Use Data-Driven Tests**
```python
@pytest.mark.parametrize("username,password,expected", [
    ("user1", "pass1", "success"),
    ("user2", "pass2", "success"),
    ("invalid", "invalid", "error"),
])
def test_login_variations(browser, username, password, expected):
    browser.get(BASE_URL)
    browser.find_element(By.NAME, "username").send_keys(username)
    browser.find_element(By.NAME, "password").send_keys(password)
    browser.find_element(By.XPATH, "//button[contains(text(), 'Login')]").click()
    
    # Assertions based on expected
    if expected == "success":
        assert "/dashboard" in browser.current_url
    else:
        assert "error" in browser.page_source.lower()
```

### 8. **Test Independent Scenarios**
```python
# ✅ GOOD - Each test is independent
def test_login(browser):
    # Register first if needed
    register(browser)
    # Then test login
    assert login(browser) == True

# ❌ BAD - Tests depend on each other
def test_1_register(browser):
    register(browser)

def test_2_login(browser):
    login(browser)  # Depends on test_1 running first!
```

---

## 🐛 TROUBLESHOOTING

### Issue 1: "No module named 'selenium'"
```bash
pip install selenium
```

### Issue 2: "ChromeDriver not found"
```bash
pip install webdriver-manager
# Or manually download from: https://chromedriver.chromium.org/
```

### Issue 3: "Element not found" or "Timeout"
```python
# Check if element selector is correct
# Use browser developer tools (F12) to inspect
# Check if page fully loaded
# Increase wait timeout

wait = WebDriverWait(driver, 20)  # Increase to 20 seconds
wait.until(EC.presence_of_element_located((By.ID, "element")))
```

### Issue 4: "Button not clickable"
```python
# Element might be hidden or not ready
wait.until(EC.element_to_be_clickable((By.ID, "button")))
button.click()

# Or scroll into view
driver.execute_script("arguments[0].scrollIntoView(true);", element)
element.click()
```

### Issue 5: Tests timeout in CI/CD
```python
# Use headless mode
options = webdriver.ChromeOptions()
options.add_argument("--headless")
driver = webdriver.Chrome(options=options)

# Reduce browser window size
options.add_argument("--window-size=1920,1080")
```

### Issue 6: "Element is stale"
```python
# Element reference becomes invalid after page reload
# Solution: Find element again after action
button = driver.find_element(By.ID, "button")
button.click()

# After click, refind instead of reusing
wait.until(EC.presence_of_element_located((By.ID, "new-element")))
```

### Issue 7: Cross-browser testing issues
```python
# Firefox
firefox_options = webdriver.FirefoxOptions()
driver = webdriver.Firefox(options=firefox_options)

# Safari (macOS only)
driver = webdriver.Safari()

# Edge
edge_options = webdriver.EdgeOptions()
driver = webdriver.Edge(options=edge_options)
```

---

## 📊 TESTING CHECKLIST

Use this checklist to ensure complete test coverage:

### Authentication Tests
- [ ] User registration (valid data)
- [ ] User registration (duplicate username)
- [ ] User registration (password mismatch)
- [ ] User registration (invalid email/format)
- [ ] User login (correct credentials)
- [ ] User login (wrong password)
- [ ] User login (non-existent user)
- [ ] User logout
- [ ] Session persistence

### Batch Management Tests
- [ ] Faculty creates batch
- [ ] Faculty creates batch with invalid threshold
- [ ] Faculty creates batch with duplicate code
- [ ] Faculty updates threshold
- [ ] Faculty views created batches
- [ ] Student joins batch (valid code)
- [ ] Student joins batch (invalid code)
- [ ] Student joins batch (already joined)
- [ ] Student views joined batches
- [ ] Batch details display correctly

### Document Upload Tests
- [ ] Student uploads PDF
- [ ] Student uploads DOCX
- [ ] Student uploads TXT
- [ ] Student uploads invalid file
- [ ] Similarity score is calculated
- [ ] Document is marked accepted
- [ ] Document is marked rejected
- [ ] Faculty views batch documents
- [ ] Faculty downloads document

### UI Tests
- [ ] All pages load without errors
- [ ] Form validation works
- [ ] Error messages display
- [ ] Success messages display
- [ ] Navigation between pages works
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Dark mode (if implemented)

### Cross-browser Tests
- [ ] Chrome
- [ ] Firefox
- [ ] Safari
- [ ] Edge

---

## 🎓 ADVANCED TOPICS

### Page Object Model (POM)
```python
# pages/login_page.py
from selenium.webdriver.common.by import By

class LoginPage:
    URL = "http://localhost:3000"
    
    def __init__(self, driver):
        self.driver = driver
    
    @property
    def username_field(self):
        return self.driver.find_element(By.NAME, "username")
    
    @property
    def password_field(self):
        return self.driver.find_element(By.NAME, "password")
    
    @property
    def login_button(self):
        return self.driver.find_element(By.XPATH, "//button[contains(text(), 'Login')]")
    
    def load(self):
        self.driver.get(self.URL)
        return self
    
    def login(self, username, password):
        self.username_field.send_keys(username)
        self.password_field.send_keys(password)
        self.login_button.click()

# test_login_pom.py
def test_login_with_pom(browser):
    login_page = LoginPage(browser)
    login_page.load()
    login_page.login("testuser", "password")
    assert browser.current_url.contains("/dashboard")
```

### Parallel Testing
```bash
# Install pytest-xdist
pip install pytest-xdist

# Run tests in parallel (4 workers)
pytest tests/ -n 4
```

### CI/CD Integration
```yaml
# .github/workflows/test.yml
name: Selenium Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
      - run: pip install -r requirements.txt
      - run: pytest tests/ --html=report.html
      - uses: actions/upload-artifact@v2
        with:
          name: test-report
          path: report.html
```

---

## 📚 ADDITIONAL RESOURCES

- [Selenium Python Documentation](https://selenium-python.readthedocs.io/)
- [pytest Documentation](https://docs.pytest.org/)
- [Selenium Best Practices](https://www.selenium.dev/documentation/test_practices/)
- [Python unittest vs pytest](https://docs.pytest.org/en/latest/unittest.html)

---

## 📝 NEXT STEPS

1. **Install dependencies**: `pip install selenium pytest requests webdriver-manager`
2. **Create test directory**: `mkdir backend/tests`
3. **Create conftest.py** with fixtures
4. **Write API tests** first (faster feedback)
5. **Write UI tests** using Selenium
6. **Run tests locally**: `pytest tests/ -v`
7. **Generate reports**: `pytest tests/ --html=report.html`
8. **Integrate with CI/CD**: GitHub Actions, GitLab CI, etc.

---

**Happy Testing! 🚀**
