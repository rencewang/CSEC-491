import scrapy
import re
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By


# import items

# import necessary components

class FangSpider(scrapy.Spider):
    name = 'fang'
    allowed_domains = ['fang.com']
    start_urls = ['https://www.fang.com/SoufunFamily.htm']
    login_url='https://passport.fang.com/'

    cookies = {}

    def parse(self, response):    
        """
        Main function
        """

        # first, simulate log in with selenium
        service = Service(ChromeDriverManager().install())
        driver = webdriver.Chrome(service=service)
        driver.get(self.login_url)
        time.sleep(2)

        # select login with account and password
        driver.find_element(By.XPATH, "//span[contains(text(),'账号密码登录')]").click()

        # input username and password for log in
        driver.find_element(By.ID, 'username').click()
        driver.find_element(By.XPATH, "//input[@id='username']").send_keys('csec491')
        driver.find_element(By.ID, "password").click()
        driver.find_element(By.XPATH, "//input[@id='password']").send_keys('Wang8100')

        submit = driver.find_element(By.XPATH, "//button[@id='loginWithPswd']")
        submit.click()
        print("Login Successful")
        time.sleep(2)

        # get cookies
        cookies = driver.get_cookies()
        for cookie in cookies:
            self.cookies[cookie['name']] = cookie['value']
        driver.quit()
