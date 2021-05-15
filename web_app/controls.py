import pandas as pd
import numpy as np
import MySQLdb


class DataStorage:

    db_params = {
        "host": "localhost", "user": "root", "passwd": "tuo7851970", "db": "crawl", "charset": "utf8"
    }

    def __init__(self) -> None:
        self.conn = MySQLdb.connect(**self.db_params)

        CATEGORYS = pd.read_sql(
            "select distinct c_name_1 from dim_category where c_name_1 is not null", self.conn)
        self.CATEGORYS = [{"label": row.c_name_1, "value": row.c_name_1}
                          for _, row in CATEGORYS.iterrows()]

        TYPES = pd.read_sql("select distinct type from dim_type", self.conn)
        self.TYPES = [{"label": row.type, "value": row.type}
                      for _, row in TYPES.iterrows()]

        POLLUS = pd.read_sql(
            "select id, vari, unit from dim_pollutant", self.conn)
        self.POLLUS = {item["id"]: (item["vari"], item["unit"])
                       for _, item in POLLUS.iterrows()}

        self.ENTERPRISES = pd.read_sql(
            "select e.*, p.lati, p.longi from dim_enterprise e join dim_position p ON e.pos_id = p.id", self.conn)
        self.MAIN_DF = pd.read_sql(
            """ select e_id, site_id, c.c_name_1 as cate, t.type, p.vari as pollutant, p.unit, pos.district, time, interval_len, value, flow, is_normal from dwd_fact_pollution_record r 
                join dim_category c on c.id = r.cate_id 
                join dim_type t on t.id = r.type_id
                join dim_pollutant p on p.id = r.pollu_id
                join dim_position pos on pos.id = r.pos_id""", self.conn)

    def close(self):
        self.conn.close()

    def load_individual_df(self, e_id, date):
        return pd.read_sql("select p.vari as pollutant, p.unit, time, SUM(value) as value from dwd_fact_pollution_record r join dim_pollutant p on r.pollu_id = p.id WHERE e_id = %s and time > '%s' and time < '%s' GROUP BY pollutant, time order by pollutant, time" % (e_id, date, np.datetime_as_string(np.datetime64(date)+1)), self.conn)

    def load_main_df(self):
        return self.MAIN_DF

    def load_category_opts(self):
        return self.CATEGORYS

    def load_type_opts(self):
        return self.TYPES

    def load_pollu_maps(self):
        return self.POLLUS

    def load_enterprise_df(self):
        return self.ENTERPRISES


TYPE_COLORS = {
    '废气企业': '#888888',
    '污水处理厂': '#CC9966',
    '危险废物企业': '#CC3333',
    '重金属企业': '#DBC5FF',
    '废气企业|废水企业': '#72A0A8',
    '废水企业': '#B2F4FF',
    '废水企业|危险废物企业': '#D675FF',
    '废水企业|废气企业|危险废物企业': '#333333',
    '废气企业|危险废物企业': '#D0ABA6',
    '废水企业|危险废物企业|土壤环境': '#AB6060',
    '垃圾处理厂': '#009966'
}

POLLU_COLORS = {
    'pH值': '#66CC99',
    '化学需氧量': '#FFCC00',
    '氨氮': '#99CCFF',
    '氮氧化物': '#6699CC',
    '二氧化硫': '#FFCC99',
    '颗粒物': '#CCCCCC',
    '总磷': '#FF6666',
    '总氮': '#006699',
    '非甲烷总烃': '#CCCC99',
    '烟尘': '#999999',
    '一氧化碳': '#99CCCC',
    '氯化氢': '#666633',
    '总砷': '#666699',
    '挥发性有机物': '#FFCCCC',
    '六价铬': '#FF9900'
}

CATE_COLORS = dict(
    GD="#FFEDA0",
    GE="#FA9FB5",
    GW="#A1D99B",
    IG="#67BD65",
    OD="#BFD3E6",
    OE="#B3DE69",
    OW="#FDBF6F",
    ST="#FC9272",
    BR="#D0D1E6",
    MB="#ABD9E9",
    IW="#3690C0",
    LP="#F87A72",
    MS="#CA6BCC",
    Confidential="#DD3497",
    DH="#4EB3D3",
    DS="#FFFF33",
    DW="#FB9A99",
    MM="#A6D853",
    NL="#D4B9DA",
    OB="#AEB0B8",
    SG="#CCCCCC",
    TH="#EAE5D9",
    UN="#C29A84",
)
