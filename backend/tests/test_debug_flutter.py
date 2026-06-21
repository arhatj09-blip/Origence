"""
Debug test to inspect Flutter app structure
"""

import pytest
from selenium.webdriver.common.by import By


def test_inspect_flutter_app(browser, base_url):
    """Inspect what elements exist in the Flutter app"""
    browser.get(base_url)
    
    # Get page source to see structure
    page_source = browser.page_source
    
    # Print all text content
    print("\n" + "="*70)
    print("PAGE CONTENT:")
    print("="*70)
    print(page_source[:2000])  # First 2000 chars
    
    # Try to find all buttons
    buttons = browser.find_elements(By.TAG_NAME, "button")
    print("\n" + "="*70)
    print(f"FOUND {len(buttons)} BUTTONS:")
    print("="*70)
    for i, btn in enumerate(buttons):
        print(f"Button {i}: {btn.text}")
    
    # Try to find all links
    links = browser.find_elements(By.TAG_NAME, "a")
    print("\n" + "="*70)
    print(f"FOUND {len(links)} LINKS:")
    print("="*70)
    for i, link in enumerate(links):
        print(f"Link {i}: {link.text}")
    
    # Try to find all text inputs
    inputs = browser.find_elements(By.TAG_NAME, "input")
    print("\n" + "="*70)
    print(f"FOUND {len(inputs)} INPUTS:")
    print("="*70)
    for i, inp in enumerate(inputs):
        print(f"Input {i}: type={inp.get_attribute('type')}, placeholder={inp.get_attribute('placeholder')}, name={inp.get_attribute('name')}")
    
    # Take screenshot
    browser.save_screenshot('debug_flutter_app.png')
    print("\n✓ Screenshot saved to: debug_flutter_app.png")
    
    # Print all text on page
    body = browser.find_element(By.TAG_NAME, "body")
    print("\n" + "="*70)
    print("ALL TEXT ON PAGE:")
    print("="*70)
    print(body.text)
