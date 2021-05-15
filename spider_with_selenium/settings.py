from selenium.webdriver.firefox.options import Options

# Spider Settings
START_DATE = "2021-01-08"
END_DATE = "2021-01-31"

# Browser Settings
FIREFOX_ARGS = Options()
BASE_URL = 'http://gzcx.sthjj.beijing.gov.cn/monitor-pub/'
FIREFOX_ARGS.add_argument("--headless")
TIMEOUT = 10

# Database Settings
MYSQL_URI = 'localhost'
DB_USER_NAME = 'root'
DB_PASSWORD = 'tuo7851970'
DB_PORT = 3306
