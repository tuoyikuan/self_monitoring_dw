--TODO 补上建表语句

-- dim_date
SET @start_date = "2021-01-01";
SET @end_date = "2021-01-31";

DROP TABLE
IF
	EXISTS dim_date;
CREATE TABLE `dim_date` (
	`date` date DEFAULT NULL,
	`id` INT NOT NULL,
	`y` SMALLINT DEFAULT NULL,
	`m` SMALLINT DEFAULT NULL,
	`d` SMALLINT DEFAULT NULL,
	`yw` SMALLINT DEFAULT NULL,
	`w` SMALLINT DEFAULT NULL,
	`q` SMALLINT DEFAULT NULL,
	`wd` SMALLINT DEFAULT NULL,
	`m_name` CHAR ( 10 ) DEFAULT NULL,
	`wd_name` CHAR ( 10 ) DEFAULT NULL,
	PRIMARY KEY ( `id` ) 
);

CREATE PROCEDURE create_dim_div ( sd date, ed date ) BEGIN
	DECLARE
		`date` date;
	
	SET date = sd;
	WHILE
			date < ed DO# populate the table with dates
			INSERT INTO dim_date SELECT
			date AS date,
			date_format( date, "%Y%m%d" ) AS id,
			YEAR ( date ) AS y,
			MONTH ( date ) AS m,
			DAY ( date ) AS d,
			date_format( @date, "%x" ) AS yw,
			WEEK ( date, 3 ) AS w,
			QUARTER ( date ) AS q,
			weekday( date )+ 1 AS wd,
			monthname( date ) AS m_name,
			dayname( date ) AS wd_name;
		
		SET date = DATE_ADD( date, INTERVAL 1 DAY );
	END WHILE;
END;

CALL create_dim_div ( @start_date, @end_date );

DROP PROCEDURE
IF EXISTS create_dim_div;

------------------------------------------------------------------------
----------------------------- dim_position -----------------------------

INSERT INTO dim_position
SELECT id, lati, longi, district
FROM ods_enterprise;

-------------------------------------------------------------------------
----------------------------- dim_enterprise ----------------------------

INSERT INTO dim_enterprise
SELECT id, `name`, introduction, type, `code`, addr, contact, phone, product, pollutant, url, period, id, category
FROM ods_enterprise;


-------------------------------------------------------------------------
-------------------------------- dim_site -------------------------------
SET @row_number = 0;
DROP TABLE IF EXISTS t_site_id_map;
CREATE TEMPORARY TABLE t_site_id_map AS SELECT
e_id,
site,
( @row_number := @row_number + 1 ) AS id 
FROM
	( SELECT e_id, site FROM ods_record GROUP BY e_id, site ) t;

INSERT INTO dim_site
SELECT
	t.id,
	t.site,
	e.start_time,
	NULL,
	e.tech,
	e.infra,
	e.id AS pos_id 
	e.id 
FROM
	t_site_id_map t
	JOIN ods_enterprise e ON t.e_id = e.id;

UPDATE dim_site
SET s_time = (
SELECT  SUBSTR(s_time_str, 1, INSTR(s_time_str,'年')-1))
WHERE INSTR(s_time_str,'年') > 0 AND SUBSTR(s_time_str, 1, INSTR(s_time_str,'年')-1) REGEXP '^[0-9]+'
;
-------------------------------------------------------------------------
------------------------------ dim_pollutant ----------------------------
INSERT INTO dim_pollutant ( vari, unit, `desc` ) 
SELECT DISTINCT
	variable,
	unit,
	NULL 
FROM
	ods_record 
WHERE
	variable IS NOT NULL;


-------------------------------------------------------------------------
------------------------------ dim_standard -----------------------------
--using python script to clean the data, and just insert the cleaned data

INSERT INTO dim_standard(name, code) VALUES ('北京卢南污水运营有限责任公司特许服务协议', NULL);
INSERT INTO dim_standard(name, code) VALUES ('印刷业挥发性有机物排放标准', 'DB11/1201-2015');
INSERT INTO dim_standard(name, code) VALUES ('危险废物焚烧大气污染物排放标准', 'DB11/503-2007');
INSERT INTO dim_standard(name, code) VALUES ('固定式燃气轮机大气污染物排放标准', 'DB11/847-2011');
INSERT INTO dim_standard(name, code) VALUES ('地表水环境质量Ⅲ类标准', 'GB 3838-2002');
INSERT INTO dim_standard(name, code) VALUES ('地表水环境质量Ⅳ类标准', 'GB 3838-2002');
INSERT INTO dim_standard(name, code) VALUES ('城市污水再生利用 城市杂用水水质', 'GB/T 18920-2002');
INSERT INTO dim_standard(name, code) VALUES ('城镇污水处理厂水污染物排放标准', 'DB11/890-2012');
INSERT INTO dim_standard(name, code) VALUES ('城镇污水处理厂污染物排放标准', 'GB 18918-2002');
INSERT INTO dim_standard(name, code) VALUES ('大气污染物综合排放标准', 'DB11/ 501-2017');
INSERT INTO dim_standard(name, code) VALUES ('工业涂装工序大气污染物排放标准', 'DB11/1226-2015');
INSERT INTO dim_standard(name, code) VALUES ('水污染物综合排放标准', 'DB11/307-2005');
INSERT INTO dim_standard(name, code) VALUES ('水污染物综合排放标准', 'DB11/307-2013');
INSERT INTO dim_standard(name, code) VALUES ('水泥工业大气污染物排放标准', 'DB11/1054-2013');
INSERT INTO dim_standard(name, code) VALUES ('水泥工业大气污染物排放标准', 'GB 4915-2013');
INSERT INTO dim_standard(name, code) VALUES ('炼油与石油化学工业大气污染物排放标准', 'DB11/447-2015');
INSERT INTO dim_standard(name, code) VALUES ('生活垃圾焚烧污染控制标准', 'GB 18458-2014');
INSERT INTO dim_standard(name, code) VALUES ('电子工业大气污染物排放标准', 'DB11/1631-2019');
INSERT INTO dim_standard(name, code) VALUES ('电镀污染物排放标准', 'GB 21900-2008.01');
INSERT INTO dim_standard(name, code) VALUES ('锅炉大气污染物排放标准', 'DB11/139-2007');
INSERT INTO dim_standard(name, code) VALUES ('锅炉大气污染物排放标准', 'DB11/139-2015');


DROP TABLE IF EXISTS std_map;
CREATE TEMPORARY TABLE std_map
AS
SELECT '水污染物综合排放标准(DB11 307-2013)' as raw, 13 as std_id
 UNION 
SELECT '水污染物综合排放标准(DB11/307-2013)', 13 
 UNION 
SELECT '水污染物综合排放标准( DB11/307-2013 )', 13 
 UNION 
SELECT '北京市水污染物综合排放标准DB11/307-2013', 13 
 UNION 
SELECT '固定式燃气轮机大气污染物排放标(DB11/847-2011)', 4 
 UNION 
SELECT '《固定式燃气轮机大气污染物排放标准》（DB11/847-2011）', 4 
 UNION 
SELECT '锅炉大气污染物排放标准(DB11/139-2015)', 21 
 UNION 
SELECT '锅炉大气污染物排放标准(DB11 139-2015)', 21 
 UNION 
SELECT 'DB11/139-2015', 21 
 UNION 
SELECT 'DG11/139-2015', 21 
 UNION 
SELECT 'GB11/139-2015', 21 
 UNION 
SELECT '《锅炉大气污染物排放标准》(DB11/139-2015)', 21 
 UNION 
SELECT '城镇污水处理厂水污染物排放标准(DB11/890-2012)', 8 
 UNION 
SELECT '城镇污水处理厂水污染物排放标准(DB11 890-2012)', 8 
 UNION 
SELECT '城镇污水处理厂水污染物排放标准( DB11/890-2012 )', 8 
 UNION 
SELECT '水污染物综合排放标准(DB11/307-2005)', 12 
 UNION 
SELECT '北京卢南污水运营有限责任公司特许服务协议', 1 
 UNION 
SELECT '电子工业大气污染物排放标准DB11/1631-2019', 18 
 UNION 
SELECT '电子工业大气污染物排放标准（DB11/ 1631-2019）', 18 
 UNION 
SELECT '北京市电子工业大气污染物排放标准（DB11/1631-2019）', 18 
 UNION 
SELECT '危险废物焚烧大气污染物排放标准( DB11/503-2007 )', 3 
 UNION 
SELECT '危险废物焚烧大气污染物排放标准(DB11 503-2007)', 3 
 UNION 
SELECT '城镇污水处理厂污染物排放标准( GB 18918-2002 )', 9 
 UNION 
SELECT '城镇污水处理厂污染物排放标准(GB 18918-2002)', 9 
 UNION 
SELECT '排口1废水执行《地表水环境质量标准》（GB3838-2002）Ⅲ类标准，总氮执行《北京市环保局关于顺义温榆河水资源利用工程地表水总氮指标意见的函》中的标准。', 5 
 UNION 
SELECT '地表水环境质量标准（GB3838-2002）Ⅳ类标准（总磷以湖、库计）', 6 
 UNION 
SELECT '大气污染物综合排放标准DB11/ 501—2017', 10 
 UNION 
SELECT '大气污染综合排放标准DB11/501-2017', 10 
 UNION 
SELECT '北京市地方标准水泥工业大气污染物排放标准', 14 
 UNION 
SELECT '水泥工业大气污染物排放标准DB11/1054-2013', 14 
 UNION 
SELECT 'DB11/1054-2013水泥工业大气污染物排放标准', 14 
 UNION 
SELECT '水泥工业大气污染物排放标准（DB11/ 1054-2013）', 14 
 UNION 
SELECT '锅炉大气污染物排放标准(DB11/139-2007)', 20 
 UNION 
SELECT '锅炉大气污染物排放标准(DB11 139-2007)', 20 
 UNION 
SELECT '工业涂装工序大气污染物排放标准DB111226-2015', 11 
 UNION 
SELECT '浓度限值执行《工业涂装工序大气污染物排放标准》（DB11/1226-2015）表1限值', 11 
 UNION 
SELECT '炼油与石油化学工业大气污染物排放标准(DB11 447-2015)', 16 
 UNION 
SELECT '炼油与石油化学工业大气污染物排放标准(DB11/447-2015)', 16 
 UNION 
SELECT '炼油与石油化学工业大气污染物排放标准DB11', 16 
 UNION 
SELECT '炼油与石油化学工业大气污染物排放标准DB11/447--2015', 16 
 UNION 
SELECT '《生活垃圾焚烧污染控制标准》（GB18458-2014）', 17 
 UNION 
SELECT '生活垃圾焚烧污染控制标准(GB 18485-2014)', 17 
 UNION 
SELECT '生活垃圾焚烧污染控制标准 GB18485-2014', 17 
 UNION 
SELECT '《城市污水再生利用  城市杂用水水质》（GB/T18920-2002)', 7 
 UNION 
SELECT '电镀污染物排放标准(GB 21900-2008.01)', 19 
 UNION 
SELECT '水泥工业大气污染物排放标准（GB 4915-2013）', 15 
 UNION 
SELECT '印刷业挥发性有机物排放标准(DB11/1201-2015 )', 2;

-------------------------------------------------------------------------
------------------------------ dim_category -----------------------------

INSERT INTO dim_category(cate)
SELECT DISTINCT category FROM ods_enterprise;


------------------------------ dim_type -----------------------------

INSERT INTO dim_type(type)
SELECT DISTINCT type FROM ods_enterprise;

-------------------------------------------------------------------------
----------------------------- dim_discharge -----------------------------

INSERT INTO dim_discharge(dst, `mode`)
SELECT destination, `mode` FROM ods_record 
GROUP BY destination, `mode`;

-------------------------------------------------------------------------
----------------------- dwd_fact_pollution_record -----------------------
-- Actually we need to construct all the facts tables through etl system
-- as soon as the monitor data stream come into the data warehouse 
-- for research aims, we just constructed it directly which is not efficient

INSERT INTO dwd_fact_pollution_record(site_id, cate_id, `type_id`, e_id, pos_id, pollu_id, std_id, disc_id, time, `value`, flow, `limit`, is_normal)
SELECT sid_map.id,c.id,t.id, e.id,e.id,p.id,std_map.std_id,d.id,r.time,r.`value`, 1 ,r.`limit`, 
	(CASE r.is_normal WHEN '是' THEN	1	ELSE 0 END)
FROM 
(
       SELECT DISTINCT 
       site, time, variable, `value`, `limit`, is_normal, standard, destination, `mode`, e_id 
       FROM ods_record
       WHERE `value` is not NULL
) AS r
LEFT JOIN ods_enterprise e ON r.e_id = e.id 
LEFT JOIN t_site_id_map sid_map ON r.site = sid_map.site AND r.e_id = sid_map.e_id
LEFT JOIN dim_category c ON e.category = c.cate
LEFT JOIN dim_pollutant p ON p.vari = r.variable
LEFT JOIN std_map ON std_map.raw = r.standard
LEFT JOIN dim_discharge d ON d.dst = r.destination
LEFT JOIN dim_type t ON e.type = t.type;

SET @tmp = DATE('2021-01-01 00:00:00');
SET @pre_sid = 0;
SET @pre_pid = 0;
UPDATE dwd_fact_pollution_record AS r
SET r.interval_len = (
SELECT  interval_length
FROM 
(
	SELECT  id 
	       ,d AS interval_length
	FROM 
	(
		SELECT  id 
		       ,site_id 
		       ,pollu_id 
		       ,cate_id 
		       ,e_id 
		       ,pos_id 
		       ,std_id 
		       ,disc_id 
		       ,`value` 
		       ,`limit` 
		       ,`time` 
		       ,is_normal 
		       ,IF(site_id = @pre_sid AND pollu_id = @pre_pid,TIMESTAMPDIFF(MINUTE,pre,cur),NULL) AS d 
		       ,@pre_sid := site_id                                                             AS tsid 
		       ,@pre_pid := pollu_id                                                            AS tpid
		FROM 
		(
			SELECT  id 
			       ,site_id 
			       ,pollu_id 
			       ,cate_id 
			       ,e_id 
			       ,pos_id 
			       ,std_id 
			       ,disc_id 
			       ,`value` 
			       ,`limit` 
			       ,is_normal 
			       ,`time` 
			       ,@tmp         AS pre 
			       ,@tmp := time AS cur
			FROM 
			(
				SELECT  *
				FROM dwd_fact_pollution_record
				ORDER BY site_id, pollu_id, `time` 
			) t 
		) m 
	) c 
) t1
WHERE r.id = t1.id );



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
---------------------------------- DWS ----------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


DROP TABLE IF EXISTS dws_pollutant_agg;
CREATE TABLE dws_pollutant_agg AS
SELECT  d.vari                    AS pollutant
       ,date
       ,max
       ,min
       ,IF(d.unit='无量纲',NULL,esti_total) AS esti_total
FROM 
(
	SELECT  pollu_id
	       ,DATE(time)                         AS date
	       ,MAX(`value`)                       AS max
	       ,MIN(`value`)                       AS min
	       ,SUM(`value` * flow * interval_len) AS esti_total
	FROM dwd_fact_pollution_record
	GROUP BY  pollu_id
	         ,date
) t
JOIN dim_pollutant d
ON t.pollu_id = d.id
ORDER BY pollutant, date;

DROP TABLE IF EXISTS dws_enterprise_agg;
CREATE TABLE dws_enterprise_agg AS
SELECT e.id, e.name, date, p.lati, p.longi, ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  e_id 
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record
GROUP BY  e_id 
         ,date 
) t
RIGHT JOIN dim_enterprise e ON t.e_id = e.id
LEFT JOIN dim_position p ON e.pos_id = p.id
ORDER BY id, date;


DROP TABLE IF EXISTS dws_site_agg;
CREATE TABLE dws_site_agg AS
SELECT site_id, s.name AS site_name, e.name AS e_name, s.param, s.tech, s.infra, date, p.lati, p.longi, ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  site_id 
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record
GROUP BY  site_id
         ,date 
) t
RIGHT JOIN dim_site s ON t.site_id = s.id
LEFT JOIN dim_position p ON s.pos_id = p.id
LEFT JOIN dim_enterprise e ON s.e_id = e.id
ORDER BY site_id, date;


DROP TABLE IF EXISTS dws_category_agg;
CREATE TABLE dws_category_agg AS
SELECT t.code_1, t.c_name_1, IF(date IS NOT NULL, date, '2021-01-01'), ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  c.code_1
       ,c.c_name_1
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record r
JOIN dim_category c ON r.cate_id = c.id
GROUP BY  c.code_1
         ,c.c_name_1
         ,date 
) t
ORDER BY code_1, date;


DROP TABLE IF EXISTS dws_type_agg;
CREATE TABLE dws_type_agg AS
SELECT type_id, ty.type, date, ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  type_id
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record
GROUP BY  type_id
         ,date 
) t
RIGHT JOIN dim_type ty ON t.type_id = ty.id
ORDER BY type_id, date;


DROP TABLE IF EXISTS dws_discharge_mode_agg;
CREATE TABLE dws_discharge_mode_agg AS
SELECT disc_id, d.mode, d.dst, date, ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  disc_id 
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record
WHERE disc_id != 0 -- exclude null
GROUP BY  disc_id
         ,date 
) t
RIGHT JOIN dim_discharge d ON t.disc_id = d.id
ORDER BY disc_id, date;


DROP TABLE IF EXISTS dws_district_agg;
CREATE TABLE dws_district_agg AS
SELECT pos_id, district, date, ph_max ,ph_min ,cod_max,cod_min,cod_esti_total,an_max ,an_min ,an_esti_total ,nox_max,nox_min,nox_esti_total,so2_max,so2_min,so2_esti_total,pm_max ,pm_min ,pm_esti_total ,tp_max ,tp_min ,tp_esti_total ,tn_max ,tn_min ,tn_esti_total ,nmh_max,nmh_min,nmh_esti_total,sm_max ,sm_min ,sm_esti_total ,co_max ,co_min ,co_esti_total ,hcl_max,hcl_min,hcl_esti_total,tas_max,tas_min,tas_esti_total,voc_max,voc_min,voc_esti_total,cr_max ,cr_min ,cr_esti_total
FROM 
(SELECT  pos_id
       ,district
       ,DATE(time)                                              AS date 
       ,MAX(IF(pollu_id=1,`value`,NULL))                        AS ph_max 
       ,MIN(IF(pollu_id=1,`value`,NULL))                        AS ph_min 
       ,MAX(IF(pollu_id=2,`value`,NULL))                        AS cod_max 
       ,MIN(IF(pollu_id=2,`value`,NULL))                        AS cod_min 
       ,SUM(IF(pollu_id=2,`value` * flow * interval_len,NULL))  AS cod_esti_total 
       ,MAX(IF(pollu_id=3,`value`,NULL))                        AS an_max 
       ,MIN(IF(pollu_id=3,`value`,NULL))                        AS an_min 
       ,SUM(IF(pollu_id=3,`value` * flow * interval_len,NULL))  AS an_esti_total 
       ,MAX(IF(pollu_id=4,`value`,NULL))                        AS nox_max 
       ,MIN(IF(pollu_id=4,`value`,NULL))                        AS nox_min 
       ,SUM(IF(pollu_id=4,`value` * flow * interval_len,NULL))  AS nox_esti_total 
       ,MAX(IF(pollu_id=5,`value`,NULL))                        AS so2_max 
       ,MIN(IF(pollu_id=5,`value`,NULL))                        AS so2_min 
       ,SUM(IF(pollu_id=5,`value` * flow * interval_len,NULL))  AS so2_esti_total 
       ,MAX(IF(pollu_id=6,`value`,NULL))                        AS pm_max 
       ,MIN(IF(pollu_id=6,`value`,NULL))                        AS pm_min 
       ,SUM(IF(pollu_id=6,`value` * flow * interval_len,NULL))  AS pm_esti_total 
       ,MAX(IF(pollu_id=7,`value`,NULL))                        AS tp_max 
       ,MIN(IF(pollu_id=7,`value`,NULL))                        AS tp_min 
       ,SUM(IF(pollu_id=7,`value` * flow * interval_len,NULL))  AS tp_esti_total 
       ,MAX(IF(pollu_id=8,`value`,NULL))                        AS tn_max 
       ,MIN(IF(pollu_id=8,`value`,NULL))                        AS tn_min 
       ,SUM(IF(pollu_id=8,`value` * flow * interval_len,NULL))  AS tn_esti_total 
       ,MAX(IF(pollu_id=9,`value`,NULL))                        AS nmh_max 
       ,MIN(IF(pollu_id=9,`value`,NULL))                        AS nmh_min 
       ,SUM(IF(pollu_id=9,`value` * flow * interval_len,NULL))  AS nmh_esti_total 
       ,MAX(IF(pollu_id=10,`value`,NULL))                       AS sm_max 
       ,MIN(IF(pollu_id=10,`value`,NULL))                       AS sm_min 
       ,SUM(IF(pollu_id=10,`value` * flow * interval_len,NULL)) AS sm_esti_total 
       ,MAX(IF(pollu_id=11,`value`,NULL))                       AS co_max 
       ,MIN(IF(pollu_id=11,`value`,NULL))                       AS co_min 
       ,SUM(IF(pollu_id=11,`value` * flow * interval_len,NULL)) AS co_esti_total 
       ,MAX(IF(pollu_id=12,`value`,NULL))                       AS hcl_max 
       ,MIN(IF(pollu_id=12,`value`,NULL))                       AS hcl_min 
       ,SUM(IF(pollu_id=12,`value` * flow * interval_len,NULL)) AS hcl_esti_total 
       ,MAX(IF(pollu_id=13,`value`,NULL))                       AS tas_max 
       ,MIN(IF(pollu_id=13,`value`,NULL))                       AS tas_min 
       ,SUM(IF(pollu_id=13,`value` * flow * interval_len,NULL)) AS tas_esti_total 
       ,MAX(IF(pollu_id=14,`value`,NULL))                       AS voc_max 
       ,MIN(IF(pollu_id=14,`value`,NULL))                       AS voc_min 
       ,SUM(IF(pollu_id=14,`value` * flow * interval_len,NULL)) AS voc_esti_total 
       ,MAX(IF(pollu_id=15,`value`,NULL))                       AS cr_max 
       ,MIN(IF(pollu_id=15,`value`,NULL))                       AS cr_min 
       ,SUM(IF(pollu_id=15,`value` * flow * interval_len,NULL)) AS cr_esti_total
FROM dwd_fact_pollution_record r
JOIN dim_position p ON r.pos_id = p.id
GROUP BY  p.district
         ,date 
) t
ORDER BY district, date;