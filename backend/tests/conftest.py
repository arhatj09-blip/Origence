"""
Pytest Configuration and Fixtures for Origence Testing
Provides common fixtures for API and UI tests
"""

import pytest
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager


# ======================== BROWSER FIXTURES ========================

@pytest.fixture(scope="session")
def browser_options():
    """Configure Chrome options"""
    options = webdriver.ChromeOptions()
    
    # Uncomment for headless mode (no visible browser window)
    # options.add_argument("--headless")
    
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--start-maximized")
    
    return options


@pytest.fixture(scope="session")
def browser(browser_options):
    """
    Fixture to provide browser instance for tests.
    Session scope = created once, used by all tests.
    """
    driver = webdriver.Chrome(
        service=Service(ChromeDriverManager().install()),
        options=browser_options
    )
    
    # Implicit wait: wait up to 10 seconds for any element
    driver.implicitly_wait(10)
    
    yield driver
    
    # Cleanup: quit browser after all tests
    driver.quit()


@pytest.fixture
def wait(browser):
    """Fixture to provide WebDriverWait for explicit waits"""
    return WebDriverWait(browser, 10)


# ======================== TEST DATA FIXTURES ========================

@pytest.fixture
def test_user():
    """Fixture providing test student credentials"""
    return {
        "username": "testuser_" + str(int(__import__('time').time())),  # Unique username
        "password": "TestPassword123!",
        "confirm_password": "TestPassword123!",
        "role": "student"
    }


@pytest.fixture
def test_faculty():
    """Fixture providing test faculty credentials"""
    return {
        "username": "testfaculty_" + str(int(__import__('time').time())),  # Unique username
        "password": "FacultyPass123!",
        "confirm_password": "FacultyPass123!",
        "role": "faculty"
    }


@pytest.fixture
def test_batch():
    """Fixture providing test batch data"""
    import time
    return {
        "batch_name": f"Test Batch {int(time.time())}",
        "batch_code": f"TEST_{int(time.time())}",
        "similarity_threshold": 0.75
    }


# ======================== URL FIXTURES ========================

@pytest.fixture
def base_url():
    """Get base URL from environment or use default"""
    return os.getenv("FRONTEND_URL", "http://localhost:3000")


# ======================== PYTEST HOOKS ========================

def pytest_sessionfinish(session, exitstatus):
    """Print success message after all tests complete"""
    if exitstatus == 0:  # 0 means all tests passed
        print("\n" + "="*70)
        print("[SUCCESS] Simple Selenium test completed successfully!")
        print("\nClosing browser in 5 seconds...")
        print("="*70)


@pytest.fixture
def api_url():
    """Get API URL from environment or use default"""
    return os.getenv("API_URL", "http://localhost:8000/api")


# ======================== PYTEST HOOKS ========================

def pytest_configure(config):
    """Configure pytest"""
    # Add custom markers
    config.addinivalue_line(
        "markers", "smoke: mark test as smoke test (fast, critical)"
    )
    config.addinivalue_line(
        "markers", "regression: mark test as regression test"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow (deselect with '-m \"not slow\"')"
    )


@pytest.fixture(autouse=True)
def reset_browser_cookies(browser):
    """Clear cookies and cache before each test"""
    browser.delete_all_cookies()
    yield


@pytest.fixture(autouse=True)
def screenshot_on_failure(browser, request):
    """Take screenshot if test fails"""
    yield
    
    # Only take screenshot if test failed
    if request.node.rep_call.failed if hasattr(request.node, 'rep_call') else False:
        screenshot_dir = "screenshots"
        if not os.path.exists(screenshot_dir):
            os.makedirs(screenshot_dir)
        
        screenshot_path = os.path.join(screenshot_dir, f"{request.node.name}.png")
        browser.save_screenshot(screenshot_path)
        print(f"\nScreenshot saved: {screenshot_path}")
