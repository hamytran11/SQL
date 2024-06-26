with full_table as 
 (with raw_fc as (

SELECT *
	, DENSE_RANK() over (PARTITION by root_category,country,Platform,`source.name` ORDER BY `Month`) as rank_check
	,1 as `ref` from 
(select  DISTINCT `Month` ,a.`Source.Name`, a.platform, a.log_date_key, country
,  CASE when country = 'USA' and a.`Source.Name` like '%AMZ%' and a.`Source.Name` not like '%furn%'  then 'Sporting Goods' 
        when country = 'USA' and a.`Source.Name` like '%WM%' and a.`Source.Name` not like '%furn%' and Channel in ('WM WFS', 'WM DSV')  then 'Sporting Goods'  
        when country = 'USA' and a.`Source.Name` like '%WM%' and a.`Source.Name` like '%furn%' and Channel in ('WM WFS', 'WM DSV')  then 'Furniture'  
        when country = 'USA' and a.`Source.Name` like '%AMZ%' and a.`Source.Name` like '%furn%' and Channel in ('FBA','FBM','AVC','AVC DS','AVC WH','AVC DI')  then 'Furniture'  
        when country = 'USA' and a.`Source.Name` like '%WF%' and a.`Source.Name` like '%furn%' and Channel in ('Wayfair','WF')  then 'Furniture'
        when country in ('CAN','MEX','JPN','ARE','SGP','AUS') then 'Sporting Goods'
        when country in ('DEU','GBR','ITA','FRA','ESP') THEN 'Sporting Goods'
        else 'check' end as root_category         
from 
(
select * from smkt_main.dim_version 
where fc_rolling = 'yes' ) a 
join smkt_main.forecast_version b 
on a.`Source.Name` = b.`Source.Name` ) e )
,
date_month as (
select `month`,1 as `ref` from 
(SELECT DISTINCT first_day_of_month as `month`,left(first_day_of_month,4) as `year`, 1 as `ref` from sc_main.dim_date ) a 
where `year` in ( '2022','2023','2024') ) 

,dim_kPI_line2 as ( 

select  DISTINCT country,root_category,platform1,`ref` from (
select country,root_category , 1 as `ref`
, case when platform = 'Amazon' then 'AMZ'
			 when platform = 'Walmart' then 'WM'
			 when platform = 'Wayfair' then 'WF'
	 else '' end as platform1
 from smkt_main.dim_kpi_line
where key_log_date = '20230529' and root_category is not null ) a )

,rank_check as (
select a.`month`,b.root_category,b.country,b.platform1 as platform ,1 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 UNION all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,2 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,3 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,4 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,5 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,6 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,7 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,8 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,9 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,10 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` 
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,11 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref`  
 union all 
 select a.`month`,b.root_category,b.country,b.platform1 as platform ,12 as rank_check
from  date_month a  
left join dim_kPI_line2 b
 on a.`ref`=b.`ref` )



select a.`month`,a.root_category, a.country, a.platform, b.`source.name`, a.rank_check  from rank_check a 
left join raw_fc b 
on a.`month`= b.`month` and a.root_category =b.root_category and a.country = b.country and a.platform = b.platform and a.rank_check=b.rank_check)

,data_is_null as (select * from full_table where `source.name` is null)


,data_is_not_null as 
(select *
,DENSE_RANK () over (PARTITION BY root_category,country,platform,rank_check ORDER BY `month` desc) as rank_sn
from (select * from full_table  
where `source.name` is not null )a) 


SELECT month1 as `month`, root_category, country, platform,sn2 as `source.name`,rank_check from 
(
select *
,DENSE_RANK() over( PARTITION by month1, root_category, country, platform,rank_check ORDER BY month2 desc ) as rank_final 
 from 
(
select a.`month`as month1, a.root_category, a.country, a.Platform, b.`month` as month2,a.`source.name` as sn1, b.`source.name` as sn2, b.rank_check, b.rank_sn 
 from data_is_null a 
join data_is_not_null b 
on a.country=b.country and a.Platform = b.Platform and a.root_category = b.root_category and a.rank_check = b.rank_check 
) a 
where month2 < month1 ) a where rank_final =1 

UNION all 

SELECT `month`, root_category, country, platform,`source.name`,rank_check from full_table where `source.name` is not null