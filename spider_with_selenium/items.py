# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy


class EnterpriseItem(scrapy.Item):
    # TODO 时间类字段用正则提取
    name = scrapy.Field()
    pol_type = scrapy.Field()
    code = scrapy.Field()
    addr = scrapy.Field()
    longi = scrapy.Field()
    lati = scrapy.Field()
    ind_category = scrapy.Field()
    contacts = scrapy.Field()
    phone_number = scrapy.Field()
    pollutants = scrapy.Field()
    products = scrapy.Field()
    start_time = scrapy.Field()
    tech = scrapy.Field()
    infr = scrapy.Field()
    id = scrapy.Field()
    com_url = scrapy.Field()
    perioud = scrapy.Field()
    desc = scrapy.Field()


class MonitorDataItem(scrapy.Item):
    e_id = scrapy.Field()
    site = scrapy.Field()
    time = scrapy.Field()
    var = scrapy.Field()
    val = scrapy.Field()
    lim = scrapy.Field()
    unit = scrapy.Field()
    norm = scrapy.Field()
    ultra = scrapy.Field()
    std = scrapy.Field()
    dest = scrapy.Field()
    mode = scrapy.Field()
    comm = scrapy.Field()


class CrawlerItem(scrapy.Item):
    # define the fields for your item here like:
    # name = scrapy.Field()
    pass
