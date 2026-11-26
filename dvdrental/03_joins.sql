-- JOIN: inner, left/right, cross, anti-join

-- Адрес, город и страна каждого покупателя
select c.customer_id, c.first_name, c.last_name, a.address, ci.city, co.country
from customer c
join address a  using (address_id)
join city ci    using (city_id)
join country co using (country_id);

-- Магазины, у которых больше 300 покупателей
select store_id, count(*) as customers
from store
join customer using (store_id)
group by store_id
having count(*) > 300;

-- Среднее число дней до возврата фильма
select c.customer_id, c.first_name, c.last_name,
       round(avg(r.return_date::date - r.rental_date::date), 2) as avg_days
from customer c
join rental r using (customer_id)
group by c.customer_id
order by avg_days desc;

-- Категории со средним сроком аренды больше 5 дней
select c.name, round(avg(f.rental_duration), 2) as avg_duration
from film f
join film_category using (film_id)
join category c using (category_id)
group by c.category_id
having avg(f.rental_duration) > 5
order by avg_duration desc;

-- Сколько раз брали каждый фильм и сколько он заработал
select f.title, count(r.rental_id) as rentals, sum(p.amount) as revenue
from film f
join inventory i using (film_id)
join rental r    using (inventory_id)
join payment p   using (rental_id)
group by f.film_id
order by revenue desc;

-- Все пары разных городов (декартово произведение)
select c1.city, c2.city
from city c1
cross join city c2
where c1.city <> c2.city;

-- Страны без магазинов сети
select co.country
from country co
left join city ci  using (country_id)
left join address a using (city_id)
left join store s   using (address_id)
group by co.country_id
having count(s.store_id) = 0;

-- Языки, на которых нет ни одного фильма: LEFT JOIN и то же самое через RIGHT JOIN
select l.name
from language l
left join film f using (language_id)
group by l.language_id
having count(f.film_id) = 0;

select l.name
from film f
right join language l using (language_id)
group by l.language_id
having count(f.film_id) = 0;

-- Сколько фильмов без известного актёрского состава
select count(*) as films_without_cast
from film f
left join film_actor fa using (film_id)
where fa.actor_id is null;

-- В каких магазинах (и городах) есть ACE GOLDFINGER
select distinct s.store_id, ci.city
from inventory i
join store s    using (store_id)
join address a  on a.address_id = s.address_id
join city ci    using (city_id)
where i.film_id = 2;

-- Магазин, где ACE GOLDFINGER ни разу не брали в аренду
select s.store_id, a.address
from store s
join address a using (address_id)
left join (
    select distinct i.store_id
    from inventory i
    join rental r using (inventory_id)
    where i.film_id = 2
) rented using (store_id)
where rented.store_id is null;
