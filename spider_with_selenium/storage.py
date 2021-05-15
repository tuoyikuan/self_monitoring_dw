import MySQLdb

from .settings import *


class MySQLStorage:
    database = 'crawl'

    def __init__(self, mysql_url=MYSQL_URI, port=DB_PORT, _user=DB_USER_NAME, _pass=DB_PASSWORD):
        self.url = mysql_url
        self.port = port,
        self._user = _user
        self._pass = _pass

    def __enter__(self):
        self.client = MySQLdb.connect(
            host=self.url,
            port=3306,
            user=self._user,
            passwd=self._pass,
            db=self.database,
            charset='utf8'
        )
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.client.close()

    def store_enterprise_item(self, item):
        try:
            cursor = self.client.cursor()
            SQL = """
            INSERT INTO CRAWL.t_enterprise(E_NAME, P_TYPE, O_CODE, ADDR, LONGI, LATI, CONT, PHONE, POLLU, 
            PROD, START_TIME, TECH, INFR, PERIOD, URL, ID, IND_CATE, INTRO) VALUES (%s,%s,%s,%s,%s,%s,%s,
            %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """
            cursor.execute(SQL, (item['name'], item['pol_type'], item['code'],
                                 item['addr'], item['longi'], item['lati'], item['contacts'], item['phone_number'],
                                 item['pollutants'],
                                 item['products'], item['start_time'], item['tech'], item['infr'], item['perioud'],
                                 item['com_url'],
                                 item['id'], item['ind_category'], item['desc']))
            return True
        except:
            return False

    def store_data_item(self, item):
        try:
            cursor = self.client.cursor()
            SQL = """
            INSERT INTO CRAWL.t_record(E_ID, `SITE`, `TIME`, `VARIABLE`, `VALUE`, `LIMIT`, UNIT, NORMAL, ULTRA,STANDARD, DESTINATION, `MODE`, `COMMENT`) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"""
            cursor.execute(SQL, (
            item['e_id'], item['site'], item['time'], item['var'], item['val'], item['lim'], item['unit'], item['norm'],
            item['ultra'], item['std'], item['dest'], item['mode'], item['comm']))
            return True
        except Exception as e:
            raise e
            # return False

    def commit(self):
        self.client.commit()
