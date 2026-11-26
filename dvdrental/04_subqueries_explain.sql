-- Подзапросы и сравнение планов через EXPLAIN ANALYZE

-- Три способа найти фильмы в категориях на «C».
-- Планировщик PostgreSQL сводит все три к похожему hash join, разница в миллисекундах.
-- Вариант с IN читает меньше колонок, поэтому обычно чуть быстрее.
explain analyze
select title, c.name
from film
join film_category using (film_id)
join category c using (category_id)
where c.name ilike 'c%';

explain analyze
select title, t.name
from film
join film_category using (film_id)
join (select category_id, name from category where name ilike 'c%') t using (category_id);

explain analyze
select title
from film
join film_category using (film_id)
where category_id in (select category_id from category where name ilike 'c%');

-- Фильмы, у которых аренда за день дороже средней
select count(*)
from film
where rental_rate / rental_duration > (select avg(rental_rate / rental_duration) from film);

-- Адреса магазинов с > 300 покупателями, город и продавец
select a.address, ci.city, st.first_name, st.last_name
from store s
join staff st  using (store_id)
join address a on a.address_id = s.address_id
join city ci   using (city_id)
where s.store_id in (
    select store_id
    from customer
    group by store_id
    having count(*) > 300
);

-- Топ-5 покупателей по числу аренд
select c.first_name, c.last_name, t.rentals
from customer c
join (
    select customer_id, count(*) as rentals
    from rental
    group by customer_id
    order by rentals desc
    limit 5
) t using (customer_id)
order by t.rentals desc;

-- Сколько продавцов получили премию (> 7300 аренд)
select count(*)
from (
    select staff_id
    from rental
    group by staff_id
    having count(*) > 7300
) t;

-- Карточка фильма: рейтинг, жанр, год, язык, число аренд и выручка (коррелированные подзапросы)
select f.title,
       f.rating,
       (select string_agg(c.name, ', ')
        from film_category fc join category c using (category_id)
        where fc.film_id = f.film_id) as genre,
       f.release_year,
       l.name as language,
       (select count(*)
        from inventory i join rental r using (inventory_id)
        where i.film_id = f.film_id) as rentals,
       (select sum(p.amount)
        from inventory i join rental r using (inventory_id) join payment p using (rental_id)
        where i.film_id = f.film_id) as revenue
from film f
join language l using (language_id)
order by revenue desc nulls last;

-- Страны без магазинов: NOT IN
select country
from country
where country_id not in (
    select ci.country_id
    from store s
    join address a using (address_id)
    join city ci   using (city_id)
);

-- Магазин, где фильм 2 ни разу не брали: NOT EXISTS
select s.store_id, a.address
from store s
join address a using (address_id)
where not exists (
    select 1
    from inventory i
    join rental r using (inventory_id)
    where i.film_id = 2 and i.store_id = s.store_id
);
