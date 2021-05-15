import json
import logging
import re
from urllib.parse import urljoin

from selenium import webdriver
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait

from spider_with_selenium.items import EnterpriseItem, MonitorDataItem
from spider_with_selenium.settings import *
from spider_with_selenium.storage import MySQLStorage
from spider_with_selenium.utils import datestr_range

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
                    datefmt='%a, %d %b %Y %H:%M:%S')


def parse_info_page(browser, info_url, storage):
    browser.get(info_url)
    # wait.until(
    #     EC.presence_of_element_located((By.XPATH, "//td[@class='f_12 clr_3']")))
    h = [item.text.strip() for item in browser.find_elements_by_xpath("//td[@class='f_12 clr_3']")]
    v = [item.text.strip() for item in browser.find_elements_by_xpath("//td[@class='f_12 clr_3 al_lt']")]
    enterprise_info = dict(zip(h, v))
    item = EnterpriseItem()
    item['id'] = e_id
    item['desc'] = browser.find_element_by_xpath("//div[@class='com_desc f_12 clr_3']").text
    item['name'] = enterprise_info.get('企业名称', None)
    item['pol_type'] = enterprise_info.get('污染源类型', None)
    item['code'] = enterprise_info.get('组织机构代码', None)
    item['addr'] = enterprise_info.get('地址', None)
    lati = enterprise_info.get('纬度', None)
    item['lati'] = float(lati) if lati else None
    longi = enterprise_info.get('经度', None)
    item['longi'] = float(longi) if longi else None
    item['contacts'] = enterprise_info.get('联系人', None)
    item['phone_number'] = enterprise_info.get('联系电话', None)
    item['start_time'] = enterprise_info.get('投运时间', None)
    item['pollutants'] = enterprise_info.get('排放污染物名称', None)
    item['products'] = enterprise_info.get('主要产品', None)
    item['tech'] = enterprise_info.get('主要生产工艺', None)
    item['infr'] = enterprise_info.get('治理设施', None)
    item['perioud'] = enterprise_info.get('生产周期', None)
    item['com_url'] = enterprise_info.get('企业官网对外信息公开网址', None)
    item['ind_category'] = enterprise_info.get('所属行业', None)
    logging.debug(item)
    storage.store_enterprise_item(item)
    storage.commit()


def not_exists_data(browser, data_url):
    browser.get(data_url)
    # wait.until(
    #     EC.presence_of_element_located((By.XPATH, "//input[@class='find_date f_12 clr_6']")))
    date_input = browser.find_element_by_xpath("//input[@class='find_date f_12 clr_6']")
    # logging.info("document.title: %s", browser.title)
    browser.execute_script("arguments[0].value = '%s'; document.title='marked'" % START_DATE, date_input)
    # logging.info("date_input.text: %s", date_input.get_attribute("value"))
    date_input.submit()
    wait.until(EC.title_is("北京市企业事业单位环境信息公开平台"))
    # logging.info("e.text: %s", e.text)
    return browser.find_element_by_xpath("//span[@class='clr_b f_wei']").text == '0'


def parse_index_page(browser, index_url):
    # TODO 修改请求的字符编码
    browser.get(index_url)
    response = browser.page_source
    if not response:
        raise SystemExit(">>>>>>>>>>>>>>>>无法加载首页<<<<<<<<<<<<<<<<<<")
    # print(response)
    return json.loads(response[response.find("["):response.rfind("]") + 1])


# TODO 代码重构 + 尝试多线程起Selenium
with webdriver.Firefox(options=FIREFOX_ARGS) as browser, MySQLStorage() as storage:
    wait = WebDriverWait(browser, TIMEOUT)
    browser.implicitly_wait(TIMEOUT)
    no_data_counts = 0
    succ_counts = 0
    # 获取企业网页列表
    logging.info("<<<<<<<<<<<<启动爬虫>>>>>>>>>>>>")
    index_url = "http://gzcx.sthjj.beijing.gov.cn/monitor-pub/js/Index_json.js"
    enterprises = parse_index_page(browser, index_url)
    logging.info("<<<<解析首页完成，待爬取%d个企业>>>>" % len(enterprises))
    sidx = 45
    for i, enterprise in enumerate(enterprises[sidx:]):
        e_id = i + sidx
        # 抓取企业信息页
        logging.info("************** %d / %d **************", e_id, len(enterprises))
        try:
            name = enterprise["title"].encode("ANSI").decode("utf-8")
        except UnicodeEncodeError:
            name = "未知编码企业，url为：%s" % enterprise["url"]
        # info_url = urljoin(BASE_URL, enterprise['url'])
        # logging.info("<<<<<<<抓取企业信息页：%s>>>>>>>", info_url)
        # try:
        #     parse_info_page(browser, info_url, storage)
        # except TimeoutException:
        #     logging.info("加载企业信息页面超时：%s" % info_url)
        #     continue
        # except NoSuchElementException:
        #     logging.info("加载企业页面错误：%s", data_url)
        # except Exception as e:
        #     logging.info("加载企业信息页面：%s 出现错误 %s" % (info_url, e))
        #     raise e

        try:
            data_url = urljoin(BASE_URL, enterprise["url"].replace("org_jbxx", "org_zdjc"))
            logging.info("<<<<<<<抓取监测数据页：%s>>>>>>>", data_url)
            if not_exists_data(browser, data_url):
                logging.info("未发现企业（%s）自行监测数据" % name)
                no_data_counts += 1
                continue
            for datestr in datestr_range(START_DATE, END_DATE):
                date_input = browser.find_element_by_xpath("//input[@class='find_date f_12 clr_6']")
                browser.execute_script("arguments[0].value = '%s'; document.title='marked'" % datestr, date_input)
                date_input.submit()
                wait.until(EC.title_is("北京市企业事业单位环境信息公开平台"))
                total_pages = int(
                    re.match(r"\d+/(\d+)页", browser.find_element_by_xpath("//span[@class='clr_b ver_mid']").text).group(
                        1))
                for _ in range(total_pages):
                    h = ["序号"]
                    h.extend([item.text.strip() for item in browser.find_elements_by_xpath("//th[@class='al_ct']")])
                    v = [item.get_attribute("title") if item.get_attribute("title") else item.text.strip() for item in
                         browser.find_elements_by_xpath("//td[@class='f_12 clr_6 al_ct']")]
                    n_cols = len(h)
                    start_idx = 0
                    while start_idx < len(v):
                        monitor_data = dict(zip(h, v[start_idx:start_idx + n_cols]))
                        try:
                            item = MonitorDataItem()
                            item['e_id'] = e_id
                            item['site'] = monitor_data.get('监测点位', None)
                            item['time'] = monitor_data.get('监测时间', None)
                            item['var'] = monitor_data.get('监测项目', None)
                            val = monitor_data.get('监测结果')
                            item['val'] = float(val) if val else None
                            item['lim'] = monitor_data.get('标准限值', None)
                            item['unit'] = monitor_data.get('单位', None)
                            item['norm'] = monitor_data.get('是否达标', None)
                            ultra = monitor_data.get('超标倍数')
                            item['ultra'] = float(ultra) if ultra else None
                            item['std'] = monitor_data.get('评价标准', None)
                            item['dest'] = monitor_data.get('排放去向', None)
                            item['mode'] = monitor_data.get('排放方式', None)
                            item['comm'] = monitor_data.get('备注', None)
                            storage.store_data_item(item)
                        except Exception:
                            pass
                        start_idx += n_cols
                    e = browser.find_element_by_xpath("//a[@class='page_norm'][3]")
                    browser.execute_script("document.title='marked'")
                    e.click()
                    wait.until(EC.title_is("北京市企业事业单位环境信息公开平台"))
                storage.commit()
                logging.info("抓取企业：（%s） %s 日期自行监测数据", name, datestr)
            succ_counts += 1
        except TimeoutException:
            logging.info("加载数据页面超时：%s, date = %s", data_url, datestr)
        except NoSuchElementException:
            logging.info("加载数据页面错误：%s", data_url)
        except Exception as e:
            raise e

    # print(enterprises)
    logging.info("爬取完成，共成功爬取%d个企业, %d个企业无数据", succ_counts, no_data_counts)
# e = browser.find_element_by_xpath("/html/body/form/div/div[3]/div/div[1]/input[1]")
# browser.execute_script("arguments[0].value = '2020-01-01'", e)
#
# index_page = "http://gzcx.sthjj.beijing.gov.cn/monitor-pub/js/Index_json.js"
