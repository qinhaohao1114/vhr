-- 21
SELECT
	longitude AS 经度,
	latitude AS 纬度,
	city_name AS 名称,
	count( * ) AS 物业总数,
	sum( area ) AS 总管理面积
FROM
	building
GROUP BY
	city_name,
	longitude,
	latitude;

-- 1 年度运营总收入
SELECT
	ifnull( sum( IF ( trans_type = 1, trans_amt, 0 ) ), 0 ) AS 年度运营总收入
FROM
	finance_trans_detail
WHERE
	budget_subject_id IS NOT NULL and DATE_FORMAT(start_time,'%Y')=DATE_FORMAT(now(),'%Y');
-- 年度运营环比
SELECT
	( now.su - old.su ) / old.su AS 环比,
CASE

		WHEN now.su - old.su > 0 THEN
		1 ELSE 2
	END AS 涨跌
FROM
	(
	SELECT
		1 AS YEAR,
		ifnull( sum( IF ( trans_type = 1, trans_amt, 0 ) ), 0 ) AS su
	FROM
		finance_trans_detail
	WHERE
		budget_subject_id IS NOT NULL
		AND DATE_FORMAT( start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' )
	) AS now
	LEFT JOIN (
	SELECT
		1 AS YEAR,
		ifnull( sum( IF ( trans_type = 1, trans_amt, 0 ) ), 0 ) AS su
	FROM
		finance_trans_detail
	WHERE
		budget_subject_id IS NOT NULL
		AND DATE_FORMAT( start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' ) - 1
	) AS old ON now.YEAR = old.YEAR;


-- 2年度支出
SELECT
	ifnull( sum( IF ( trans_type = 0, trans_amt, 0 ) ), 0 ) as 年度运营总支出
FROM
	finance_trans_detail
WHERE
	budget_subject_id IS NOT NULL and DATE_FORMAT(start_time,'%Y')=DATE_FORMAT(now(),'%Y');

	SELECT
	( now.su - old.su ) / old.su AS 环比,
CASE

		WHEN now.su - old.su > 0 THEN
		1 ELSE 2
	END AS 涨跌
FROM
	(
	SELECT
		1 AS YEAR,
		ifnull( sum( IF ( trans_type = 0, trans_amt, 0 ) ), 0 ) AS su
	FROM
		finance_trans_detail
	WHERE
		budget_subject_id IS NOT NULL
		AND DATE_FORMAT( start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' )
	) AS now
	LEFT JOIN (
	SELECT
		1 AS YEAR,
		ifnull( sum( IF ( trans_type = 0, trans_amt, 0 ) ), 0 ) AS su
	FROM
		finance_trans_detail
	WHERE
		budget_subject_id IS NOT NULL
		AND DATE_FORMAT( start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' ) - 1
	) AS old ON now.YEAR = old.YEAR;

-- 管理总面积

select sum(area) as 管理总面积 from building;

-- 物业总数
SELECT
	count( DISTINCT ( display_name ) ) as 物业总数
FROM
	building
WHERE
	is_deleted = 0;

-- 在租面积

SELECT
	ifnull(
		sum(
		CASE

				WHEN cs.`space_id` IS NOT NULL THEN
				s.`area`
				WHEN ( cs.`space_id` IS NULL AND cs.`floor_id` IS NOT NULL AND cs.`building_id` IS NOT NULL ) THEN
				f.`area`
				WHEN cs.`space_id` IS NULL
				AND cs.`floor_id` IS NULL THEN
					b.`area` ELSE 0
				END
				),
				0
			) AS rentOutArea
		FROM
			contract c
			LEFT JOIN contract_space cs ON c.`id` = cs.`contract_id`
			LEFT JOIN building b ON b.id = cs.`building_id`
			LEFT JOIN floor f ON f.`id` = cs.`floor_id`
			LEFT JOIN space s ON s.id = cs.`space_id`
		WHERE
			c.contract_type = 1
			AND c.STATUS = 2
			AND c.is_deleted = 0
			AND cs.is_deleted = 0;
-- 	租户个数

select count(DISTINCT signer_id) from contract where contract_type=1 and `status`=2;

-- 收入构成

SELECT
  bs.`name` as 收入名称,
 ifnull( sum( IF ( trans_type = 1, trans_amt, 0 ) ), 0 ) as 金额
FROM
	finance_trans_detail f
	LEFT JOIN budget_subject bs on f. budget_subject_id=bs.id
WHERE
	DATE_FORMAT( f.start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' )
		AND f.trans_type = 1
 GROUP BY bs.`name`;

-- 支出构成   办公电话费

SELECT
  bs.`name` as 支出名称,
 ifnull( sum( IF ( trans_type = 0, trans_amt, 0 ) ), 0 ) as 金额
FROM
	finance_trans_detail f
	LEFT JOIN budget_subject bs on f. budget_subject_id=bs.id
WHERE
	DATE_FORMAT( f.start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' )
		AND f.trans_type = 0
 GROUP BY bs.`name`;

 -- 收支趋势
SELECT
  DATE_FORMAT( f.start_time, '%Y-%m' ) as 日期,
  ifnull( sum( IF ( trans_type = 0, trans_amt, 0 ) ), 0 ) as 支出金额,
	ifnull( sum( IF ( trans_type = 1, trans_amt, 0 ) ), 0 ) as 收入金额
FROM
	finance_trans_detail f
	LEFT JOIN budget_subject bs on f. budget_subject_id=bs.id
WHERE
	DATE_FORMAT( f.start_time, '%Y' ) = DATE_FORMAT( now( ), '%Y' ) GROUP BY DATE_FORMAT( f.start_time, '%Y-%m' );

-- 租户租赁面积 top 5 待确认

SELECT
	signer_name as 租户,
	sum(area) as 面积
FROM
	contract JOIN contract_rent_plan
WHERE
	contract_type = 1
	AND `status` = 2 GROUP BY signer_name ORDER BY sum(area) desc LIMIT 5;

-- 资产管理面积
SELECT
	b.display_name AS 物业点,
	sum( b.area ) AS 管理面积,
	IFNULL( sum( c1.area ), 0 ) as 租赁面积,
	(sum( b.area )-IFNULL( sum( c1.area ), 0 ))/sum( b.area ) AS 空置率
FROM
	building b
	LEFT JOIN (
	SELECT
	cs.area,
	cs.building_id
FROM
	contract_space cs
	JOIN contract c ON cs.contract_id = c.id
	AND c.`status` = 2
	) c1 on b.id=c1.building_id
GROUP BY
	b.display_name
ORDER BY
	sum( b.area ) DESC
-- 	LIMIT 5;

-- 物业性质分布
SELECT
	CASE b.property_type
	WHEN 1 THEN
		'自有'
	when 2 then
	  '租赁'
	ELSE
		'公租房'
END as 物业性质,
count(*) as 数量
FROM
	building b
GROUP BY
	b.property_type;







