from scrapy import cmdline

# enabling the below line will scrape the entire website
# cmdline.execute("scrapy crawl fang".split())

# enabling the below line will scrape for wuhan, or any single city
# modify the links in city_spider.py to scrape for other cities
cmdline.execute("scrapy crawl city".split())