# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
from itemadapter import ItemAdapter
from scrapy.exporters import CsvItemExporter

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


    def process_item(self, item, spider):
        """
        For each item, save to csv and sql
        """

        if isinstance(item, CityItem):
            self.url_exporter.export_item(item)

        elif isinstance(item, NewHouseItem):
            self.newhouse_exporter.export_item(item)

        elif isinstance(item, SecondHandHouseItem):
            self.secondhandhouse_exporter.export_item(item)
        
        return item


    def close_spider(self, spider):
        self.url_file.close()
        self.newhouse_file.close()
        self.secondhandhouse_file.close()