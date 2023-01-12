/*1.Find all product(s) categories (names) which have been profitable every year over the previous year*/

with t1 as (
	SELECT p.prod_category, to_char(s.time_id, 'YYYY') as calendar_year,
	       sum(sum(amount_sold)) over (PARTITION BY p.prod_category, to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'YYYY')
	                                   range between unbounded preceding and current row)::numeric(16,2) as sales,
	       case when sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 1 preceding and 1 preceding)::numeric(16,2) is null then 0 else 
	       sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 1 preceding and 1 preceding)::numeric(16,2) end as prev_year,
	       case when sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 2 preceding and 2 preceding)::numeric(16,2) is null then 0 else 
	       sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 2 preceding and 2 preceding)::numeric(16,2) end as prev_year2,
	       case when sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 3 preceding and 3 preceding)::numeric(16,2) is null then 0 else 
	       sum(sum(amount_sold)) over (PARTITION BY p.prod_category order by to_char(s.time_id, 'YYYY')::numeric (16,2)
	                                   range between 3 preceding and 3 preceding)::numeric(16,2) end as prev_year3 
	FROM sh.products p
	JOIN sh.sales s ON p.prod_id=s.prod_id
	group by p.prod_category, to_char(s.time_id, 'YYYY')
	) 
SELECT prod_category, calendar_year, sales, prev_year, sales-prev_year as difference
from t1
where prod_category in (
      select prod_category
      from t1
      where calendar_year='2001'
      and sales-prev_year>0
      and prev_year-prev_year2>0
      and prev_year2-prev_year3>0
      group by prod_category, calendar_year);
     
/*2.	Design the 3 top customers in sales report for each group by date of birth in {1900 - 1950}, {1951-2000}, 
 {2000} that contributes more than 0.2% of all sales at least once in all the years.*/
select age_group, id, customer, cust_all_sales, c_rank 
from (
with t1 as(
 select case when c.cust_year_of_birth between 1900 and 1950 then '{1900 - 1950}' 
		     when c.cust_year_of_birth between 1951 and 2000 then '{1951 - 2000}' 
		     else '{2000}' end as age_group, 
	    c.cust_id as id, concat(c.cust_first_name, ' ', c.cust_last_name) as customer, to_char(s.time_id, 'YYYY'),
		sum(amount_sold) as cust_y_sales,
		sum(sum(amount_sold)) over (PARTITION BY c.cust_id, c.cust_first_name 
		                      range between unbounded preceding and current row)::numeric(16,2) as cust_all_sales,
		(sum(sum(amount_sold)) over (PARTITION BY c.cust_id, c.cust_first_name, to_char(s.time_id, 'YYYY') 
			                   range between unbounded preceding and current row)::numeric(16,2)/
		sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') 
			                  range between unbounded preceding and current row)::numeric(16,2)*100) as cust_share
		from sh.customers c 
		join sh.sales s 
		on c.cust_id = s.cust_id 
		group by age_group, c.cust_id, c.cust_first_name, to_char(s.time_id, 'YYYY')
		) 
select age_group, id, customer, cust_all_sales, 
       rank () over (PARTITION by age_group order by cust_all_sales desc) as c_rank
from t1
where cust_share>0.2) as t2
where c_rank<4;

/*3.	Compare sales for each month for “Cameras” (channel “Partners” channel_id=2) between 1998 and 1999 years.*/
--i copmare jan1999 to jan1998 and so on, if theres no month number in the table then there are no sales in both years
select distinct p.prod_subcategory_desc, to_char(s.time_id, 'mm') as month,
       case when t1.cur_y is null then (0-t1.prev_y) else (t1.cur_y-t1.prev_y) end as delta
from sh.products p
join sh.sales s on p.prod_id = s.prod_id 
join sh.channels c on s.channel_id = c.channel_id 
join 
	(select p.prod_subcategory_desc, to_char(s.time_id, 'YYYY') as years, to_char(s.time_id, 'MM') as month,
	       sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'MM') order by to_char(s.time_id, 'YYYY')
				                       range between current row and current row)::numeric(16,2) as cur_y,
		   case when sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'MM') order by to_char(s.time_id, 'YYYY')::numeric (16,2)
				                       range between 1 preceding and 1 preceding)::numeric(16,2) is null 
	       then 0 else sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'MM') order by to_char(s.time_id, 'YYYY')::numeric (16,2)
				                       range between 1 preceding and 1 preceding)::numeric(16,2) 
		   end as prev_y	                       
	from sh.products p
	join sh.sales s on p.prod_id = s.prod_id 
	join sh.channels c on s.channel_id = c.channel_id 
	where c.channel_desc = 'Partners'
	and p.prod_subcategory_desc = 'Cameras'
	and to_char(s.time_id, 'YYYY') in ('1998', '1999')
	group by p.prod_subcategory_desc, to_char(s.time_id, 'YYYY'), to_char(s.time_id, 'MM')
	order by to_char(s.time_id, 'MM'), to_char(s.time_id, 'YYYY')
	) as t1
on to_char(s.time_id, 'YYYY')= t1.years and to_char(s.time_id, 'MM') = t1.month
where c.channel_desc = 'Partners'
and p.prod_subcategory_desc = 'Cameras'
and to_char(s.time_id, 'YYYY') in ('1998', '1999')
and t1.years='1999'
order by month;

/*4.	Design Count Quantity report for the years 1999, 2000, 2001 which is broken down by country region, 
 promo category (except NO PROMOTION)  and by product min price 
(0-100  100-500  500-1000  over 1000).  Show total sales across country region.*/
/*dont understand if there s need to show totals across the country region by years or not,
that is why created both variants (2last columns)*/
select distinct to_char(s.time_id, 'YYYY') as years, c.country_region, p.promo_name, 
       case when pr.prod_min_price between 0 and 99 then
       to_char(count(s.prod_id) over (partition by to_char(s.time_id, 'YYYY'), c.country_region, p.promo_name), '9,999,999,999')
       else 'N/A' end as price_0_99,
       case when pr.prod_min_price between 100 and 499 then
       to_char(count(s.prod_id) over (partition by to_char(s.time_id, 'YYYY'), c.country_region, p.promo_name), '9,999,999,999')
       else 'N/A' end as price_100_499, 
       case when pr.prod_min_price between 500 and 999 then
       to_char(count(s.prod_id) over (partition by to_char(s.time_id, 'YYYY'), c.country_region, p.promo_name), '9,999,999,999')
       else 'N/A' end as price_500_999, 
       case when pr.prod_min_price > 999 then
       to_char(count(s.prod_id) over (partition by to_char(s.time_id, 'YYYY'), c.country_region, p.promo_name), '9,999,999,999')
       else 'N/A' end as price_1000,
       sum(sum(s.amount_sold)) over (partition by to_char(s.time_id, 'YYYY'), c.country_region order by to_char(s.time_id, 'YYYY')
       range between unbounded preceding and current row)::numeric(16,2) as region_sales_current_y,
       sum(sum(s.amount_sold)) over (partition by c.country_region order by c.country_region
       range between unbounded preceding and current row)::numeric(16,2) as region_sales_total
from sh.sales s join sh.customers cst on s.cust_id = cst.cust_id 
join sh.countries c on cst.country_id = c.country_id 
join sh.promotions p on s.promo_id =p.promo_id 
join sh.products pr on s.prod_id = pr.prod_id 
where p.promo_name not in ('NO PROMOTION #')
and to_char(s.time_id, 'YYYY') in ('1999', '2000', '2001')
group by s.time_id, c.country_region, p.promo_name, pr.prod_min_price, s.prod_id
order by years, c.country_region, p.promo_name;

/*Extra 
Design report showing the total of sales in each month of year. Each column is a month and each row is a year.*/
select year, jan, feb, mar, apr, may, jun, jul, aug, sept, oct, nov, dec
from (
select to_char(s.time_id, 'YYYY') as year, to_char(s.time_id, 'MM') as month, 
       sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 11 preceding and 11 preceding)::numeric(16,2) as jan,	
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 10 preceding and 10 preceding)::numeric(16,2) as feb,			
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 9 preceding and 9 preceding)::numeric(16,2) as mar,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 8 preceding and 8 preceding)::numeric(16,2) as apr,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 5 preceding and 5 preceding)::numeric(16,2) as may,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 6 preceding and 6 preceding)::numeric(16,2) as jun,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 5 preceding and 5 preceding)::numeric(16,2) as jul,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 4 preceding and 4 preceding)::numeric(16,2) as aug,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 3 preceding and 3 preceding)::numeric(16,2) as sept,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 2 preceding and 2 preceding)::numeric(16,2) as oct,                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between 1 preceding and 1 preceding)::numeric(16,2) as nov,				                   
	   sum(sum(amount_sold)) over (PARTITION BY to_char(s.time_id, 'YYYY') order by to_char(s.time_id, 'MM')::numeric(16,2)
				                   range between current row and current row)::numeric(16,2) as dec		                   
from sh.sales s
group by to_char(s.time_id, 'YYYY'), to_char(s.time_id, 'MM')) as t1
where month::numeric(16,2)=12;
				                