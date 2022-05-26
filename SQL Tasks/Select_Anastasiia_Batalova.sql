--task1: Выведите в алфавитном порядке названия комедиий, выпущенных в период с 2000 по 2004 год
--there and after i use not capital letters, cause my editor always changes them to this version
select title
from film
where release_year between 2000 and 2004 --can also be in ('2000', '2001', '2002', '2003', '2004')
and film_id in 
    (select film_id 
    from film_category
    where category_id in 
        (select category_id
        from category
        where upper(name)='COMEDY'))
order by title;

--task2: Доход (revenue) магазинов проката в 2017 году (колонки address и address1 – как одна строка, revenue)
select concat(a.address, ' ', a.address2) as store_address, sum(p.amount) as revenue --the tables don't have address1 column, so I combined the address with the address2
from address a join store s on a.address_id=s.address_id 
join inventory i on s.store_id=i.store_id 
join rental r on i.inventory_id=r.inventory_id 
join payment p on r.rental_id=p.rental_id 
WHERE p.payment_date > '2016-12-31' AND p.payment_date < '2018-01-01'
group by store_address
order by revenue desc;
    
--task3: Top-3 актеров по числу фильмов в которых они приняли участие (колонки first_name, last_name, number_of_movies ), сортировка по числу фильмов в порядке уменьшения
select a.first_name as actor_first_name, a.last_name as actor_lat_name, count(distinct fa.film_id) as number_of_movies
from actor a left join film_actor fa on a.actor_id=fa.actor_id 
group by actor_first_name, a.last_name
order by count(distinct fa.film_id) desc 
limit 3;

/*task4: Количество комедий, боевиков и фильмов ужасов по годам (в строке: год, количество комедий,
количество ужасов и количество боевиков), отсортировано по убыванию лет*/

select f.release_year as year, 
count(case when upper(c.name)='COMEDY' then 1 else null end) as Count_of_comedies, 
count(case when upper(c.name)='HORROR' then 1 else null end) as Count_of_horrors,
count(case when upper(c.name)='ACTION' then 1 else null end) as Count_of_actions
from film f left join film_category fc on f.film_id=fc.film_id left join category c on fc.category_id=c.category_id 
group by f.release_year
order by f.release_year desc;

/*task5: Какие актеры не снимались дольше остальных (в сроке полное имя актера/актрисы, год выхода
последнего фильма)*/
with max_years as (
    select a.first_name, a.last_name, max(f.release_year) as mry
    from actor a join film_actor fa on a.actor_id=fa.actor_id 
    join film f on fa.film_id=f.film_id
    group by a.first_name, a.last_name)
select first_name|| ' ' ||last_name|| ' ' ||mry as actors_last_movie_year from max_years
where mry = (select min(mry) from max_years) 
; 