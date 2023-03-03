# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
from itemadapter import ItemAdapter
from scrapy.exporters import CsvItemExporter
import copy
import pymysql
from pymysql import cursors
from twisted.enterprise import adbapi

from fang.items import CityItem, NewHouseItem, SecondHandHouseItem

# receive item and perform action over the item
class FangPipeline:
    def __init__(self):
        self.url_file = open("files/urls.csv", "wb")
        self.url_exporter = CsvItemExporter(self.url_file)

        self.newhouse_file = open("files/newhouse.csv", "wb")
        self.newhouse_exporter = CsvItemExporter(self.newhouse_file)

        self.secondhandhouse_file = open("files/secondhandhouse.csv", "wb")
        self.secondhandhouse_exporter = CsvItemExporter(self.secondhandhouse_file)

        db = {
            'host': '127.0.0.1',
            'port': 3306,
            'user': 'root',
            'password': 'root',
            'database': 'fang',
            'charset': 'utf8',
            'cursorclass': cursors.DictCursor
        }
        self.dbpool = adbapi.ConnectionPool('pymysql', **db)
        self._sql = None

    def process_item(self, item, spider):
        """
        For each item, save to csv and sql
        """

        if isinstance(item, CityItem):
            self.url_exporter.export_item(item)
            async_item = copy.deepcopy(item)
            defer_item = self.dbpool.runInteraction(self.url_item, async_item)
            defer_item.addErrback(self.handle_error, item, spider)

        elif isinstance(item, NewHouseItem):
            self.newhouse_exporter.export_item(item)
            async_item = copy.deepcopy(item)
            defer_item = self.dbpool.runInteraction(self.newhouse_item, async_item)
            defer_item.addErrback(self.handle_error, item, spider)

        elif isinstance(item, SecondHandHouseItem):
            self.secondhandhouse_exporter.export_item(item)
            async_item = copy.deepcopy(item)
            defer_item = self.dbpool.runInteraction(self.secondhandhouse_item, async_item)
            defer_item.addErrback(self.handle_error, item, spider)
        
        return item


    def url_item(self, cursor, item):
        insert_sql = """
            insert into city(city, newhouse_url, secondhandhouse_url)
            VALUES (%s, %s, %s)
        """
        cursor.execute(insert_sql, (item['city'], item['newhouse_url'], item['secondhandhouse_url']))

    
    def newhouse_item(self, cursor, item):
        insert_sql = """
            insert into newhouse(city, municipal_district, listing_title, community_name, price, rooms, area, address, url)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(insert_sql, (item['city'], item['municipal_district'], item['listing_title'], item['community_name'], item['price'], item['rooms'], item['area'], item['address'], item['url']))


    def secondhandhouse_item(self, cursor, item):
        insert_sql = """
            insert into secondhandhouse(city, municipal_district, listing_title, community_name, price, rooms, area, address, url, year, floor, orientation, unit_price)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(insert_sql, (item['city'], item['municipal_district'], item['listing_title'], item['community_name'], item['price'], item['rooms'], item['area'], item['address'], item['url'], item['year'], item['floor'], item['orientation'], item['unit_price']))

    
    def handle_error(self, error, item):
        print(error)

    def close_spider(self):
        self.url_file.close()
        self.newhouse_file.close()
        self.secondhandhouse_file.close()