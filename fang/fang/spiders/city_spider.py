import scrapy
import re
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By

from fang.items import NewHouseItem, SecondHandHouseItem
from scrapy.spidermiddlewares.httperror import HttpError
from twisted.internet.error import DNSLookupError
from twisted.internet.error import TimeoutError, TCPTimedOutError

CITY = '武汉'
CITY_NEW_HOUSE_URL = 'https://wuhan.newhouse.fang.com'
CITY_SECOND_HAND_HOUSE_URL = 'https://wuhan.esf.fang.com'
CRAWL_LINKS = [CITY_NEW_HOUSE_URL, CITY_SECOND_HAND_HOUSE_URL]

class CitySpider(scrapy.Spider):
    name="city"
    allowed_domains = ['fang.com']
    start_urls = ['https://wh.fang.com']
    login_url='https://passport.fang.com/'
    cookies = {}

    def parse(self, response):

        # first, simulate log in with selenium
        service = Service(ChromeDriverManager().install())
        options = webdriver.ChromeOptions()
        prefs = {"profile.managed_default_content_settings.images": 2}
        options.add_experimental_option("prefs", prefs)
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

        # # crawl through the new house page
        yield scrapy.Request(url=CITY_NEW_HOUSE_URL, cookies=self.cookies, callback=self.parse_newhouse, meta={'city': CITY})

        # # crawl through the second hand house page
        # yield scrapy.Request(url=CITY_SECOND_HAND_HOUSE_URL, cookies=self.cookies, callback=self.parse_secondhandhouse, meta={'city': CITY})

    
    def parse_newhouse(self, response):
        city = response.meta.get('city')
        print("Processing new house listings for " + city + "--------------------------------------------------")
        if response.status != 200:
            print("Invalid page: " + response.status)
            return

        newhouse_list = response.xpath("//div[contains(@class,'nl_con')]//li[contains(@id,'lp')]")
        for li in newhouse_list:
            title, url, municipal_district, address, rooms, area, price,  = '', '', '', '', '', '', ''

            title = li.xpath(".//div[@class='nlcd_name']/a/text()").get()
            url = 'https:' + li.xpath(".//div[@class='nlcd_name']/a/@href").get()

            house_type = li.xpath(".//div[contains(@class,'house_type')]/a/text()").getall()
            rooms = list(filter(lambda x:x.endswith(("居","上")), house_type))
            rooms = "/".join(rooms) # reformat rooms field

            area = "".join(li.xpath(".//div[contains(@class,'house_type')]/text()").getall()).split()
            area = area[-1] if area else ''

            address_span = li.xpath(".//div[@class='address']/a/span").get()
            # some entries have district in span, others do not
            if address_span:
                span_text = li.xpath(".//div[@class='address']/a/span/text()").get().strip()
                municipal_district = re.sub(r'\[|\]', '', span_text)
                address = li.xpath(".//div[@class='address']/a/@title").get()
            else:
                text = ' '.join(li.xpath(".//div[@class='address']/a/text()").getall()).split()
                if text:
                   if len(text)==1:
                       address = text[0]
                   else:
                       municipal_district = re.sub(r'\[|\]','',text[0])
                       address = text[1]
                
            price = li.xpath(".//div[@class='nhouse_price']//text()").getall()

            item = NewHouseItem(city=city, community_name=title, listing_title=title, url=url, municipal_district=municipal_district, address=address, rooms=rooms, area=area, price=price)
            yield item

        # handle pagniation, go to next page
        next_page = response.urljoin(response.xpath("//li[@class='fr']/a[@class='next']/@href").get())
        if next_page:
            yield scrapy.Request(url=next_page, cookies=self.cookies, callback=self.parse_newhouse, meta={'city': city})

    
    def parse_secondhandhouse(self, response):
        city = response.meta.get('city')
        print("Processing second hand house listings for " + city + "--------------------------------------------------")
        if response.status != 200:
            print("Invalid page: " + response.status)
            return

        secondhand_list = response.xpath("//dl[@dataflag='bg']")
        for dl in secondhand_list:
            title, url, municipal_district, address, rooms, area, price, year, floor, orientation, unit_price, community_name = ('',) * 12

            title = dl.xpath(".//h4[@class='clearfix']/a/@title").get()
            url_text = dl.xpath(".//h4[@class='clearfix']/a/@href").get()
            url = response.urljoin(url_text)

            listing_detail = "".join(dl.xpath(".//p[@class='tel_shop']/text()").getall()).split()
            for item in listing_detail:
                if '室' in item:
                    rooms = item
                elif '㎡' in item:
                    area = item
                elif '层' in item:
                    floor = item
                elif '向' in item:
                    orientation = item
                elif '年' in item:
                    year = item

            community_name = dl.xpath(".//p[@class='add_shop']/a/@title").get()
            address = dl.xpath(".//p[@class='add_shop']/span/text()").get()

            price_text = " ".join(dl.xpath(".//dd[@class='price_right']/span/text()").getall()).split()
            price = dl.xpath(".//dd[@class='price_right']/span/b/text()").get() + price_text[0]
            unit_price = price_text[1]

            item = SecondHandHouseItem(city=city, listing_title=title, url=url, rooms=rooms, area=area, floor=floor, orientation=orientation, year=year, community_name=community_name, address=address, price=price, unit_price=unit_price)
            yield item

        # handle pagniation, go to next page
        next_page = response.urljoin(response.xpath("//div[@class='page_al']/p[2]/a/@href").get())
        if next_page:
            yield scrapy.Request(url=next_page, cookies=self.cookies, callback=self.parse_secondhandhouse, meta={'city': city})


    def errback(self, failure):
        self.logger.error(repr(failure))
        if failure.check(HttpError):
            # thrown by HttpErrorMiddleware
            # receive additional status codes
            response = failure.value.response
            self.logger.error('HttpError on %s', response.url)

        elif failure.check(DNSLookupError):
            # thrown by Request
            request = failure.request
            self.logger.error('DNSLookupError on %s', request.url)

        elif failure.check(TimeoutError, TCPTimedOutError):
            request = failure.request
            self.logger.error('TimeoutError on %s', request.url)