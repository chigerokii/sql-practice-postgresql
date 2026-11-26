-- CTE и рекурсивные запросы

-- Фильмы по длине: short / medium / long
with typed as (
    select film_id,
           case when length < 30 then 'short'
                when length < 90 then 'medium'
                else 'long' end as type
    from film
)
select type, count(*)
from typed
group by type;

-- Сотрудник и число оформленных аренд
with rentals_by_staff as (
    select staff_id, count(*) as rentals
    from rental
    group by staff_id
)
select s.last_name, s.first_name, r.rentals
from staff s
join rentals_by_staff r using (staff_id);

-- Страны без магазинов сети
with countries_with_store as (
    select distinct ci.country_id
    from store s
    join address a using (address_id)
    join city ci   using (city_id)
)
select country
from country
where country_id not in (select country_id from countries_with_store);

-- Рекурсия по дереву: всё, что входит в Европу, с уровнем вложенности
create temp table locations (
    id        integer primary key,
    parent_id integer references locations (id),
    name      text
);

insert into locations values
    (1, null, 'Планета Земля'),
    (2, 1, 'Континент Евразия'),
    (3, 1, 'Континент Северная Америка'),
    (4, 2, 'Европа'),
    (5, 4, 'Россия'),
    (6, 4, 'Германия'),
    (7, 5, 'Москва'),
    (8, 5, 'Санкт-Петербург'),
    (9, 6, 'Берлин');

with recursive tree (id, name, level, path) as (
    select id, name, 0, name
    from locations
    where name = 'Европа'
    union all
    select l.id, l.name, t.level + 1, t.path || ' → ' || l.name
    from locations l
    join tree t on l.parent_id = t.id
)
select repeat('    ', level) || name as node, level, path
from tree
order by path;

-- Первые 10 чисел Фибоначчи
with recursive fib (i, a, b) as (
    select 1, 0::bigint, 1::bigint
    union all
    select i + 1, b, a + b
    from fib
    where i < 10
)
select i, b as fib
from fib;

-- Календарь без пропусков: аренды по дням, включая дни без аренд
with recursive days (d) as (
    select min(rental_date)::date from rental
    union all
    select d + 1 from days where d < (select max(rental_date)::date from rental)
)
select d, count(r.rental_id) as rentals
from days
left join rental r on r.rental_date::date = d
group by d
order by d;
