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

WUHAN_URL = 'https://wh.fang.com'
WUHAN_SECONDARY_URL = 'https://wh.esf.fang.com'
WUHAN_NEW_URL = 'https://wh.newhouse.fang.com/house/s/'

# Using request library:
# ExampleURL = 'https://wuhan.esf.fang.com/chushou/3_199480507.htm'
# page = requests.get(ExampleURL)
# print(page.text)

# Using headless mode:
options = Options()
options.add_argument("--headless=new")
options.add_argument("--window-size=1920,1200")

service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=options)
driver.get("https://www.nintendo.com/")

# print(driver.page_source, driver.title, driver.current_url, sep='\n')

driver.quit()