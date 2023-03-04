# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy

class CityItem(scrapy.Item):
    province = scrapy.Field()
    city = scrapy.Field()
    newhouse_url = scrapy.Field()
    secondhandhouse_url = scrapy.Field()


class NewHouseItem(scrapy.Item):
    province = scrapy.Field()
    city = scrapy.Field()
    municipal_district = scrapy.Field()
    listing_title = scrapy.Field()
    community_name = scrapy.Field()
    price = scrapy.Field()
    rooms = scrapy.Field()
    area = scrapy.Field()
    address = scrapy.Field()
    url = scrapy.Field()


class SecondHandHouseItem(scrapy.Item):
    province = scrapy.Field()
    city = scrapy.Field()
    municipal_district = scrapy.Field()
    listing_title = scrapy.Field()
    community_name = scrapy.Field()
    price = scrapy.Field()
    rooms = scrapy.Field()
    area = scrapy.Field()
    address = scrapy.Field()
    url = scrapy.Field()

    # below fields are only available for second hand houses
    year = scrapy.Field()
    floor = scrapy.Field()
    orientation = scrapy.Field()
    unit_price = scrapy.Field()