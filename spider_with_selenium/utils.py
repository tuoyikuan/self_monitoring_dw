import pandas as pd


def datestr_range(start_date="2020-01-01", end_date="2020-02-28"):
    """
    返回从start_date到end_date的有效日期字符串序列
    :param start_date:
    :param end_date:
    :return: ['2020-01-01', ... , '2020-02-28']
    """
    return [d.strftime("%Y-%m-%d") for d in pd.date_range(start_date, end_date)]


def header_str2dict(headers: str):
    h_dict = {}
    for l in headers.splitlines()[1:]:
        k, v = (item.strip() for item in l.split(':', maxsplit=1))
        h_dict[k] = v
    return h_dict
