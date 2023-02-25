# First, scrape Fang.com for all listings in a given city
# Then, scrape each listing for the following information:
#   - Listing ID
#   - Listing URL
#   - Listing Title
#   - Listing Price
#   - Listing Address
#   - Listing Community
#   - Listing Area
#   - Listing Floor Area
#   - Listing Room Number

import requests
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By

import time

WUHAN_URL = 'https://wh.fang.com'
WUHAN_SECONDARY_URL = 'https://wh.esf.fang.com'
WUHAN_NEW_URL = 'https://wh.newhouse.fang.com/house/s/'

# Using request library:
# ExampleURL = 'https://wuhan.esf.fang.com/chushou/3_199480507.htm'
# page = requests.get(ExampleURL)
# print(page.text)

# # Using headless mode:
# options = Options()
# # options.add_argument("--headless=new")
# prefs = {"profile.managed_default_content_settings.images": 2}
# options.add_argument("--window-size=1920,1200")
# options.add_experimental_option("prefs", prefs)


# service = Service(ChromeDriverManager().install())
# driver = webdriver.Chrome(service=service, options=options)
# driver.get("https://wuhan.esf.fang.com/chushou/3_199480507.htm?rfss=2-c1c9cd9581193b3ffa-ea")

# print(driver.page_source, driver.title, driver.current_url, sep='\n')

# driver.quit()

service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service)
driver.get('https://passport.fang.com/')
time.sleep(2)

# js_phone = "document.getElementsByTagName('dd')[0].style.display='none'"
# js_account= "document.getElementsByTagName('dd')[1].style.display='block'"
# driver.execute_script(js_phone)
# driver.execute_script(js_account)

# select login with account and password
driver.find_element(By.XPATH, "//span[contains(text(),'账号密码登录')]").click()

# input username and password for log in
driver.find_element(By.ID, 'username').click()
username = driver.find_element(By.XPATH, "//input[@id='username']").send_keys('csec491')
driver.find_element(By.ID, "password").click()
password = driver.find_element(By.XPATH, "//input[@id='password']").send_keys('Wang8100')
submit = driver.find_element(By.XPATH, "//button[@id='loginWithPswd']")
submit.click()

print("Login Successful")
time.sleep(2)

# get cookies
cookies = driver.get_cookies()
print(cookies)
driver.quit()