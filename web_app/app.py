# 1.部署 2.css
# Import required libraries
import copy
from logging import PlaceHolder
import pathlib
import dash
import math
import datetime as dt
from dash_html_components.Div import Div
import pandas as pd
import numpy as np
from dash.dependencies import Input, Output, State, ClientsideFunction
import dash_core_components as dcc
import dash_html_components as html
import plotly.graph_objs as go
import plotly.express as px
from pandas.tseries.offsets import CustomBusinessDay

# Multi-dropdown options
from controls import TYPE_COLORS, POLLU_COLORS,  DataStorage


# get relative data folder
PATH = pathlib.Path(__file__).parent
DATA_PATH = PATH.joinpath("data").resolve()

app = dash.Dash(
    __name__, meta_tags=[{"name": "viewport", "content": "width=device-width"}]
)
server = app.server

# Download pickle file

########################
# urllib.request.urlretrieve(
#     "https://raw.githubusercontent.com/plotly/datasets/master/dash-sample-apps/dash-oil-and-gas/data/points.pkl",
#     DATA_PATH.joinpath("points.pkl"),
# )
# points = pickle.load(open(DATA_PATH.joinpath("points.pkl"), "rb"))
########################


# Load data
store = DataStorage()
df = store.load_main_df()
enterprise_df = store.load_enterprise_df()

# Create controls

# TODO 每种污染物曲线颜色需固定  -> graph object的color属性支持字段名的str表示

category_opts = store.load_category_opts()
type_opts = store.load_type_opts()

# Create global chart template
mapbox_access_token = "pk.eyJ1IjoidHlrMTY2NTkiLCJhIjoiY2tuY3U0Zmh5MXA1cDJwcW55ZXpoanRpdCJ9.Z9ny7FfMJX--twxYH6LMSQ"
# TODO 把category换成c_name_1
map_layout = dict(
    autosize=True,
    automargin=True,
    margin=dict(l=30, r=30, b=20, t=40),
    hovermode="closest",
    plot_bgcolor="#F9F9F9",
    paper_bgcolor="#F9F9F9",
    legend=dict(font=dict(size=10), orientation="h"),
    title="监测站点空间分布",
    mapbox=dict(
        accesstoken=mapbox_access_token,
        style="light",
        center=dict(lon=116.40, lat=39.90),
        zoom=8,
    ),
)

# Create app layout
app.layout = html.Div(
    [
        dcc.Store(id="aggregate_data"),
        # empty Div to trigger javascript file for graph resizing
        html.Div(id="output-clientside"),
        html.Div(
            [
                html.Div(
                    [
                        html.Img(
                            src=app.get_asset_url("dash-logo.png"),
                            id="plotly-image",
                            style={
                                "height": "60px",
                                "width": "auto",
                                "margin-bottom": "25px",
                            },
                        )
                    ],
                    className="one-third column",
                ),
                html.Div(
                    [
                        html.Div(
                            [
                                html.H3(
                                    "北京市企业排污自行监测数据平台",
                                    style={"margin-bottom": "0px"},
                                ),
                                html.H5(
                                    "信息概览", style={"margin-top": "0px"}
                                ),
                            ]
                        )
                    ],
                    className="one-half column",
                    id="title",
                )
            ],
            id="header",
            className="row flex-display",
            style={"margin-bottom": "25px"},
        ),
        html.Div(
            [
                html.Div(
                    [
                        html.Span(
                            "数据筛选器",
                            id="filter_label",
                            className="label"
                        ),
                        html.P(
                            "按照日期进行过滤 (或通过右图时间轴) :",
                            className="control_label",
                        ),
                        # TODO 时间更改为 2021-01-01  -> 2021-01-31
                        dcc.RangeSlider(
                            id="year_slider",
                            min=0,
                            max=31,
                            value=[0, 31],
                            className="dcc_control",
                        ),

                        html.P("按照排污类别过滤：", className="control_label"),
                        dcc.RadioItems(
                            id="type_selector",
                            options=[
                                {"label": "全部", "value": "all"},
                                {"label": "废气企业", "value": "gas"},
                                {"label": "废水企业", "value": "water"},
                                {"label": "危险废物企业", "value": "solid"},
                                {"label": "自定义", "value": "customize"},
                            ],
                            value="customize",
                            labelStyle={"display": "inline-block"},
                            className="dcc_control",
                        ),
                        dcc.Dropdown(
                            id="types",
                            options=type_opts,
                            multi=True,
                            value=["废气企业", "废水企业",
                                   "危险废物处理企业", "垃圾处理厂", "污水处理厂"],
                            placeholder="下拉选择包含排污类别",
                            className="dcc_control",
                        ),

                        html.P("按照所属行业过滤：", className="control_label"),
                        dcc.RadioItems(
                            id="category_selector",
                            options=[
                                {"label": "全部", "value": "all"},
                                {"label": "能源行业", "value": "energy"},
                                {"label": "化工行业", "value": "chemical"},
                                {"label": "环境行业", "value": "environment"},
                                {"label": "制造业", "value": "manu"},
                                {"label": "自定义", "value": "customize"},
                            ],
                            value="customize",
                            labelStyle={"display": "inline-block"},
                            className="dcc_control",
                        ),
                        dcc.Dropdown(
                            id="categories",
                            options=category_opts,
                            multi=True,
                            value=[
                                "电力、热力生产和供应业",
                                "水的生产和供应业",
                                "生态保护和环境治理业",
                                "化学原料和化学制品制造业",
                                "非金属矿物制品业",
                                "汽车制造业",
                                "石油、煤炭及其他燃料加工业"
                            ],
                            placeholder="下拉选择包含行业",
                            className="dcc_control",
                        ),
                        dcc.Checklist(
                            id="lock_selector",
                            options=[
                                {"label": "Lock camera", "value": "locked"}],
                            className="dcc_control",
                            value=[],
                        ),

                        html.P("按照区县过滤：", className="control_label"),

                        dcc.RadioItems(
                            id="district_selector",
                            options=[
                                {'label': '全部', 'value': 0},
                                {'label': '自定义', 'value': 1},
                            ],
                            value=0,
                            labelStyle={"display": "inline-block"},
                            className="dcc_control",
                        ),
                        dcc.Dropdown(
                            id="districts",
                            options=[{'label': '朝阳', 'value': '朝阳'},
                                     {'label': '丰台', 'value': '丰台'},
                                     {'label': '海淀', 'value': '海淀'},
                                     {'label': '门头沟', 'value': '门头沟'},
                                     {'label': '房山', 'value': '房山'},
                                     {'label': '通州', 'value': '通州'},
                                     {'label': '顺义', 'value': '顺义'},
                                     {'label': '昌平', 'value': '昌平'},
                                     {'label': '大兴', 'value': '大兴'},
                                     {'label': '怀柔', 'value': '怀柔'},
                                     {'label': '平谷', 'value': '平谷'},
                                     {'label': '密云', 'value': '密云'},
                                     {'label': '延庆', 'value': '延庆'}],
                            multi=True,
                            value=['朝阳', '丰台', '海淀', '门头沟', '房山', '通州',
                                   '顺义', '昌平', '大兴', '怀柔', '平谷', '密云', '延庆'],
                            placeholder="下拉选择包含排污类别",
                            className="dcc_control",
                        ),
                    ],
                    className="pretty_container four columns",
                    id="cross-filter-options",
                ),
                html.Div(
                    [
                        html.Div(
                            [
                                html.Div(
                                    [html.H6(id="n_enterprises"),
                                     html.P("企业")],
                                    id="enterprises",
                                    className="mini_container",
                                ),
                                html.Div(
                                    [html.H6(id="c_site"), html.P("监测点位")],
                                    id="gas",
                                    className="mini_container",
                                ),
                                html.Div(
                                    [html.H6(id="c_record"), html.P("监测记录")],
                                    id="oil",
                                    className="mini_container",
                                ),
                                html.Div(
                                    [html.H6(id="c_abnormal"), html.P("超标记录")],
                                    id="water",
                                    className="mini_container",
                                ),
                            ],
                            id="info-container",
                            className="row container-display",
                        ),
                        html.Div(
                            [dcc.Graph(id="count_graph")],
                            id="countGraphContainer",
                            className="pretty_container",
                        ),
                    ],
                    id="right-column",
                    className="eight columns",
                ),
            ],
            className="row flex-display",
        ),
        html.Div(
            [
                html.Div(
                    [dcc.Graph(id="main_graph")],
                    className="pretty_container seven columns",
                ),
                html.Div(
                    [
                        dcc.DatePickerSingle(
                            id="individual_date_picker",
                            date="2021-01-01",
                            min_date_allowed="2021-01-01",
                            max_date_allowed="2021-01-31",
                        ),
                        dcc.Graph(id="individual_graph")],
                    className="pretty_container five columns",
                ),
            ],
            className="row flex-display",
        ),
        html.Div(
            [
                html.Div(
                    [dcc.Graph(id="summary_graph")],
                    className="pretty_container seven columns",
                ),
                html.Div(
                    [dcc.Graph(id="aggregate_graph")],
                    className="pretty_container five columns",
                ),
            ],
            className="row flex-display",
        ),
    ],
    id="mainContainer",
    style={"display": "flex", "flex-direction": "column"},
)


def filter_dwd_records(df, categories, types, year_slider, districts):
    dff = df[
        df["cate"].isin(categories)
        & df["type"].isin(types)
        & df["district"].isin(districts)
        & (df["time"] > np.datetime64('2021-01-01') + np.timedelta64(int(year_slider[0]), 'D'))
        & (df["time"] < np.datetime64('2021-01-01') + np.timedelta64(int(year_slider[1]), 'D'))
    ]
    return dff


def filter_enterprises(e_df, ids):
    return e_df[e_df["id"].isin(ids)]


# Create callbacks
app.clientside_callback(
    ClientsideFunction(namespace="clientside", function_name="resize"),
    Output("output-clientside", "children"),
    [Input("count_graph", "figure")],
)


@app.callback(
    Output("aggregate_data", "data"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
)
def update_summary_text(categories, types, year_slider, districts):
    dff = filter_dwd_records(df, categories, types, year_slider, districts)
    n_records = len(dff)
    n_sites = len(dff['site_id'].unique())
    n_abnormals = (dff['is_normal'] != 1).sum()
    return n_sites, n_records, n_abnormals


# Radio -> multi
@app.callback(
    Output("types", "value"), [Input("type_selector", "value")]
)
def display_types(selector):
    if selector == "all":
        return [item['value'] for item in type_opts]
    elif selector == "gas":
        return ["废气企业"]
    elif selector == "water":
        return ["废水企业"]
    elif selector == "solid":
        return ["危险废物企业"]
    return ["废气企业", "废水企业", "危险废物处理企业", "垃圾处理厂", "污水处理厂"]


@app.callback(
    Output("categories", "value"), [Input("category_selector", "value")]
)
def display_categories(selector):
    if selector == "all":
        return [item['value'] for item in category_opts]
    elif selector == "energy":
        return [
            "电力、热力生产和供应业",
            "水的生产和供应业"
        ]
    elif selector == "environment":
        return [
            "生态保护和环境治理业"
        ]
    elif selector == "chemical":
        return [
            "非金属矿物制品业",
            "化学原料和化学制品制造业",
            "黑色金属冶炼和压延加工业",
            "造纸和纸制品业",
            "石油、煤炭及其他燃料加工业"
        ]
    elif selector == "manu":
        return [
            "汽车制造业",
            "计算机、通信和其他电子设备制造业",
            "家具制造业",
            "通用设备制造业",
            "金属制品业",
            "通用设备制造业"
        ]
    return [
        "电力、热力生产和供应业",
        "水的生产和供应业",
        "生态保护和环境治理业",
        "化学原料和化学制品制造业",
        "非金属矿物制品业",
        "汽车制造业",
        "石油、煤炭及其他燃料加工业", ]


@app.callback(Output("districts", "value"), [Input("district_selector", "value")])
def display_districts(district_selector):
    if district_selector == 0:
        return ['朝阳', '丰台', '海淀', '门头沟', '房山', '通州', '顺义', '昌平', '大兴', '怀柔', '平谷', '密云', '延庆']
    elif district_selector == 1:
        return []
    return []


# Slider -> count graph
@app.callback(Output("year_slider", "value"), [Input("count_graph", "selectedData")])
def update_year_slider(count_graph_selected):

    if count_graph_selected is None:
        return [0, 31]
    print(type(count_graph_selected["points"][0]['x']),
          count_graph_selected["points"][0]['x'])
    nums = [(np.datetime64(point['x']) - np.datetime64('2021-01-01')).astype(int)
            for point in count_graph_selected["points"]]
    return [min(nums), max(nums)]


# Selectors -> enterprise count text
@app.callback(
    Output("n_enterprises", "children"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
)
def update_enterprise_count_text(categories, types, year_slider, districts):

    dff = filter_dwd_records(df, categories, types, year_slider, districts)
    return dff['e_id'].unique().size


@app.callback(
    [
        Output("c_site", "children"),
        Output("c_record", "children"),
        Output("c_abnormal", "children"),
    ],
    [Input("aggregate_data", "data")],
)
def update_text(data):
    return data[0], data[1], data[2]

# Selectors -> individual date picker


@app.callback(
    Output("individual_date_picker", "date"),
    [Input("year_slider", "value")]
)
def update_individual_date_picker(year_slider):
    return np.datetime64('2021-01-01') + np.timedelta64(int(year_slider[0]))


@app.callback(
    [
        Output("individual_date_picker", "min_date_allowed"),
        Output("individual_date_picker", "max_date_allowed"),
    ],
    [Input("year_slider", "value")]
)
def update_individual_date_picker(year_slider):
    return np.datetime64('2021-01-01') + np.timedelta64(int(year_slider[0])),  np.datetime64('2021-01-01') + np.timedelta64(int(year_slider[1]))


# Selectors -> main graph
@app.callback(
    Output("main_graph", "figure"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
    [State("lock_selector", "value"), State("main_graph", "relayoutData")],
)
def make_main_figure(
    categories, types, year_slider, districts, selector, main_graph_layout
):

    dff = filter_dwd_records(df, categories, types, year_slider, districts)
    dff = filter_enterprises(enterprise_df, dff['e_id'].unique())

    traces = []
    for t, dfff in dff.groupby("type"):
        trace = dict(
            type="scattermapbox",
            lon=dfff["longi"],
            lat=dfff["lati"],
            text=dfff["name"],
            customdata=dfff["id"],
            name=t,
            marker=dict(size=4, opacity=0.95, color=TYPE_COLORS[t]),
        )
        traces.append(trace)

    # relayoutData is None by default, and {'autosize': True} without relayout action
    if main_graph_layout is not None and selector is not None and "locked" in selector:
        if "mapbox.center" in main_graph_layout.keys():
            lon = float(main_graph_layout["mapbox.center"]["lon"])
            lat = float(main_graph_layout["mapbox.center"]["lat"])
            zoom = float(main_graph_layout["mapbox.zoom"])
            map_layout["mapbox"]["center"]["lon"] = lon
            map_layout["mapbox"]["center"]["lat"] = lat
            map_layout["mapbox"]["zoom"] = zoom

    figure = dict(data=traces, layout=map_layout)
    return figure


# Main graph -> individual graph
@app.callback(Output("individual_graph", "figure"),
              [
    Input("main_graph", "hoverData"),
    Input("individual_date_picker", "date"),
])
def make_individual_figure(main_graph_hover, date):

    # 指定企业，指定日期的监测曲线
    layout_individual = copy.deepcopy(map_layout)

    chosen_eid = main_graph_hover["points"][0]["customdata"] if main_graph_hover else 0

    dff = store.load_individual_df(chosen_eid, date)

    if dff.empty:
        annotation = dict(
            text="No data available",
            x=0.5,
            y=0.5,
            align="center",
            showarrow=False,
            xref="paper",
            yref="paper",
        )
        layout_individual["annotations"] = [annotation]
        data = []
    else:
        data = [
            dict(
                type="scatter",
                mode="lines+markers",
                name="%s (%s)" % (g[0], g[1]),
                x=record["time"],
                y=record["value"],
                line=dict(shape="spline", smoothing=1,
                          width=1),
                marker=dict(symbol="diamond-open", color=POLLU_COLORS[g[0]],),
            )
            for g, record in dff.groupby(["pollutant", "unit"])
        ]
        layout_individual["template"] = dict(layout="plotly_dark")
        layout_individual["title"] = enterprise_df[enterprise_df["id"]
                                                   == chosen_eid]["name"].iloc[0]
    figure = dict(data=data, layout=layout_individual)
    return figure


# Selectors -> aggregate graph
@app.callback(
    Output("aggregate_graph", "figure"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
)
def make_aggregate_figure(categories, types, year_slider, districts):

    layout_aggregate = copy.deepcopy(map_layout)

    dff = filter_dwd_records(df, categories, types, year_slider, districts)
    agg = (dff[["pollutant", "time", "value", "flow", "interval_len"]]
           .groupby([dff["pollutant"], dff["time"].dt.date])
           .apply(lambda x: np.log((x.value * x.flow * x.interval_len).sum())))

    data = [
        dict(
            type="scatter",
            mode="lines",
            name=pollutant,
            x=agg[pollutant].index,
            y=agg[pollutant].values,
            line=dict(shape="spline", smoothing=2,
                      color=POLLU_COLORS[pollutant], ),
        )
        for pollutant in agg.index.levels[0] if pollutant != 1
    ]
    layout_aggregate["title"] = "逐日总估测排放量变化曲线"
    layout_aggregate["automargin"] = True
    figure = dict(data=data, layout=layout_aggregate)
    return figure


# Selectors -> summary graph
@app.callback(
    Output("summary_graph", "figure"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
)
def make_summary_figure(categories, types, year_slider, districts):

    layout_pie = copy.deepcopy(map_layout)

    dff = filter_dwd_records(df, categories, types, year_slider, districts)
    agg = (dff.groupby(["cate", "pollutant"])
              .apply(lambda x: np.log((x.value * x.flow * x.interval_len).sum())))
    colors = px.colors.qualitative.Pastel1
    data = [
        dict(
            type="bar",
            x=agg[cate].index,
            y=agg[cate].values,
            marker=dict(color=colors[i]),
            name=cate
        )
        for i, cate in enumerate(agg.index.levels[0])
    ]

    layout_pie["barmode"] = "stack"
    layout_pie["xaxis"] = dict(categoryorder="total descending")
    layout_pie["font"] = dict(color="#777777")
    layout_pie["legend"] = dict(
        font=dict(size=10), orientation="h", bgcolor="rgba(0,0,0,0)"
    )
    # 用一个优雅的方式更换配色模板
    del layout_pie["automargin"]
    figure = go.Figure(data=data, layout=layout_pie)

    figure.update_layout(title={
                             'text': "累计估算排放量: {} 至 {}".format(
                                 np.datetime_as_string(np.datetime64(
                                     '2021-01-01') + int(year_slider[0])),
                                 np.datetime_as_string(np.datetime64(
                                     '2021-01-01') + int(year_slider[1]) - 1)
                             ),
                             'x':0.5,
                         }
                        )
    figure.update_yaxes(automargin=True)
    figure.update_xaxes(automargin=True)
    return figure


# Selectors -> count graph
@app.callback(
    Output("count_graph", "figure"),
    [
        Input("categories", "value"),
        Input("types", "value"),
        Input("year_slider", "value"),
        Input("districts", "value"),
    ],
)
def make_count_figure(categories, types, year_slider, districts):

    layout_count = copy.deepcopy(map_layout)
    dff = filter_dwd_records(df, categories, types, [0, 31], districts)
    count_df = dff['value'].groupby(df.time.dt.date).count()
    colors = []
    for i in range(0, 31):
        if i >= int(year_slider[0]) and i < int(year_slider[1]):
            colors.append("rgb(123, 199, 255)")
        else:
            colors.append("rgba(123, 199, 255, 0.2)")

    data = [
        dict(
            type="scatter",
            mode="markers",
            x=count_df.index,
            y=count_df.values / 2,
            name="No. Monitor Records",
            opacity=0,
            hoverinfo="skip",
        ),
        dict(
            type="bar",
            x=count_df.index,
            y=count_df.values,
            marker=dict(color=colors),
        ),
    ]

    layout_count["title"] = "每日发布监测记录总数"
    layout_count["dragmode"] = "select"
    layout_count["showlegend"] = False
    layout_count["autosize"] = True

    figure = dict(data=data, layout=layout_count)
    return figure


# Main
if __name__ == "__main__":
    # app.run_server(debug=True)
    app.run_server()
