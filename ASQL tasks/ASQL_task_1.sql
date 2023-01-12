/*Task1. создать куб по странам, городам, заказчикам, трем мес€цам, категории продукта, подкатегории продукта, продукту, 
каналам, промокатегории.
¬ыставить фильтры до 5-ти, но так, чтобы данных в итоговой таблице дл€ ответа на вопрос было больше двух
–ешить задачи (как на лекции - таблица должна давать ответ на вопрос):*/
--1)—амый покупающий заказчик в городе
select * from (
        select case when grouping(cou.country_name) = 0 then cou.country_name else 'ALL COUNTRIES' end as country_name,
		       case when grouping(cus.cust_city) = 0 then cus.cust_city else 'ALL CITIES' end as cust_city,
		       case when grouping(cus.cust_first_name) = 0 then cus.cust_first_name else 'ALL CUSTOMERS' end as cust_first_name,
		       case when grouping(t.calendar_month_desc) = 0 then t.calendar_month_desc else 'ALL MONTHS' end as calendar_month_desc,
		       case when grouping(p.prod_category) = 0 then p.prod_category else 'ALL CATEGORIES' end as prod_category,
		       case when grouping(p.prod_subcategory) = 0 then p.prod_subcategory else 'ALL SUBCATEGORIES' end as prod_subcategory,
		       case when grouping(p.prod_name) = 0 then p.prod_name else 'ALL PRODUCTS' end as prod_name, 
		       case when grouping(c.channel_desc) = 0 then c.channel_desc else 'ALL CHANNELS'end as channel_desc, 
		       case when grouping(pro.promo_category) = 0 then pro.promo_category else 'ALL PROMO CATEGORIES' end as promo_category,
       sum(s.amount_sold)::Numeric(16,2),
       rank () over (partition by  cus.cust_city order by sum(s.amount_sold) desc) as rank_city_customer
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by cube (cou.country_name, cus.cust_city, cus.cust_first_name, t.calendar_month_desc, p.prod_category, 
              p.prod_subcategory, p.prod_name, c.channel_desc, pro.promo_category)              
having grouping(cou.country_name, cus.cust_city, cus.cust_first_name, t.calendar_month_desc, p.prod_category, 
               p.prod_subcategory, p.prod_name, c.channel_desc, pro.promo_category) in (319)  
order by 2 ) as cube
where rank_city_customer = 1;

--2)ѕродукт на который заказчик готов тратить больше всего денег
select * from (
        select case when grouping(cou.country_name) = 0 then cou.country_name else 'ALL COUNTRIES' end as country_name,
		       case when grouping(cus.cust_city) = 0 then cus.cust_city else 'ALL CITIES' end as cust_city,
		       case when grouping(cus.cust_first_name) = 0 then cus.cust_first_name else 'ALL CUSTOMERS' end as cust_first_name,
		       case when grouping(t.calendar_month_desc) = 0 then t.calendar_month_desc else 'ALL MONTHS' end as calendar_month_desc,
		       case when grouping(p.prod_category) = 0 then p.prod_category else 'ALL CATEGORIES' end as prod_category,
		       case when grouping(p.prod_subcategory) = 0 then p.prod_subcategory else 'ALL SUBCATEGORIES' end as prod_subcategory,
		       case when grouping(p.prod_name) = 0 then p.prod_name else 'ALL PRODUCTS' end as prod_name, 
		       case when grouping(c.channel_desc) = 0 then c.channel_desc else 'ALL CHANNELS'end as channel_desc, 
		       case when grouping(pro.promo_category) = 0 then pro.promo_category else 'ALL PROMO CATEGORIES' end as promo_category,
       sum(s.amount_sold)::Numeric(16,2),
       rank () over (partition by  cus.cust_first_name order by sum(s.amount_sold) desc) as rank_customer_product
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by cube (cou.country_name, cus.cust_city, cus.cust_first_name, t.calendar_month_desc, p.prod_category, 
              p.prod_subcategory, p.prod_name, c.channel_desc, pro.promo_category)              
having grouping(cou.country_name, cus.cust_city, cus.cust_first_name, t.calendar_month_desc, p.prod_category, 
               p.prod_subcategory, p.prod_name, c.channel_desc, pro.promo_category) in (443)  
order by 2 ) as cube
where rank_customer_product = 1;

--3)ѕродажи за мес€ц и составл€ющие этого мес€ца по каналам, промокатегории и страны
select case when grouping(t.calendar_month_desc) = 0 then t.calendar_month_desc else 'ALL MONTHS' end as calendar_month_desc,
       case when grouping(c.channel_desc) = 0 then c.channel_desc else 'ALL CHANNELS' end as channel_desc,
       case when grouping(pro.promo_category) = 0 then pro.promo_category else 'ALL PROMO CATEGORIES' end as promo_category,
       case when grouping(cou.country_name) = 0 then cou.country_name else 'ALL COUNTRIES' end as country_name,
       sum(s.amount_sold)::Numeric(16,2)
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by t.calendar_month_desc,
      cube ((c.channel_desc, pro.promo_category, cou.country_name))
order by 1, 2, 3, 4;
                         
--4)фраза от заказчика: "’очу оставить только тот канал в котором продажи продукта X в городе Y наивысшие"
select * from (select case when grouping(c.channel_desc) = 0 then c.channel_desc else 'ALL CHANNELS' end as channel_desc,
                      case when grouping(cus.cust_city) = 0 then cus.cust_city else 'ALL CITIES' end as cust_city,
                      case when grouping(p.prod_name) = 0 then p.prod_name else 'ALL PRODUCTS' end as prod_name,
       	       sum(s.amount_sold)::Numeric(16,2),
	           rank () over (partition by  p.prod_name order by sum(s.amount_sold) desc) as rank_prod_in_the_city
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by cube ((c.channel_desc, cus.cust_city, p.prod_name))
) as cube 
where rank_prod_in_the_city = 1
order by 1, 4 desc;

--5)*extra -->написать таску самому и решить. „ем интересне тем лучше(:
--продукт, который €вл€етс€ лидером продаж в наибольшем количестве стран (сумма продаж)
select distinct final.prod_name,  sum(s.amount_sold)::Numeric(16,2)
from (
select prod_name, count(country_name), 
       rank () over (partition by  prod_name order by count(country_name) desc) as rank_country_product_count
from (
--написать селект на посчитать кол-во стран на предыдушей таблице
select cou.country_name,
       p.prod_name, 
       sum(s.amount_sold)::Numeric(16,2),
       rank () over (partition by  cou.country_name order by sum(s.amount_sold) desc) as rank_country_product
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by cube (cou.country_name, p.prod_name)              
having grouping(cou.country_name, p.prod_name) in (0)  
order by 1, 3 desc, 2) as leaders
where rank_country_product = 1
group by prod_name) as final
join sh.products p on final.prod_name = p.prod_name
join sh.sales s on s.prod_id = p.prod_id
where rank_country_product_count = 1
group by final.prod_name;

/*Task2. P.S. ”слови€ дл€ фильтров как и в (1). —оздать группинг сет (конкантинейшн приветствуетс€) который:
колонки: город + промокатегории + три мес€ца + категори€ + подкатегори€ + сумма
сабтоталы: 
город + три мес€ца
промокатегории + подкатегори€ 
категори€ + город 
три мес€ца + промокатегории 
город + подкатегори€
категори€ + промокатегории
гранд тотал --город + промокатегории + три мес€ца + категори€ + подкатегори€*/       
select case when grouping(cus.cust_city) = 0 then cus.cust_city else 'ALL CITIES' end as cust_city,
       case when grouping(pro.promo_category) = 0 then pro.promo_category else 'ALL PROMO CATEGORIES' end as promo_category,
       case when grouping(t.calendar_month_desc) = 0 then t.calendar_month_desc else 'ALL MONTHS' end as calendar_month_desc,
       case when grouping(p.prod_category) = 0 then p.prod_category else 'ALL CATEGORIES' end as prod_category,
       case when grouping(p.prod_subcategory) = 0 then p.prod_subcategory else 'ALL SUBCATEGORIES' end as prod_subcategory,
       sum(s.amount_sold)::Numeric(16,2)
from sh.sales s
join sh.products p
on s.prod_id = p.prod_id
join sh.channels c
on c.channel_id = s.channel_id
join sh.times t
on t.time_id = s.time_id
join sh.customers cus
on s.cust_id = cus.cust_id
join sh.countries cou
on cus.country_id = cou.country_id
join sh.promotions pro
on s.prod_id = pro.promo_id
where t.calendar_month_desc in ('2000-12', '2000-11', '2000-10')
and p.prod_name in ('Bounce', 'Deluxe Mouse', 'External 8X CD-ROM', 'Music CD-R') 
and cou.country_name in ('Australia', 'France', 'United Kingdom')
and cus.cust_first_name like 'B%'
group by grouping sets ((cus.cust_city), pro.promo_category, ()), 
         grouping sets (t.calendar_month_desc, p.prod_category, p.prod_subcategory, ())
having grouping(cus.cust_city, pro.promo_category, t.calendar_month_desc, p.prod_category, p.prod_subcategory)
               in (11, 14, 13, 19, 22, 21, 31)
order by cust_city, promo_category, calendar_month_desc, prod_category, prod_subcategory;                         