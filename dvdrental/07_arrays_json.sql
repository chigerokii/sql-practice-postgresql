-- Массивы и JSON

-- Три способа найти значение в массиве
select title, special_features from film where special_features && array['Behind the Scenes'];
select title, special_features from film where special_features @> array['Behind the Scenes'];
select title, special_features from film where 'Behind the Scenes' = any (special_features);

-- Сколько раз каждый покупатель брал фильмы с «Behind the Scenes»: CTE…
with bts as (
    select film_id
    from film
    where special_features @> array['Behind the Scenes']
)
select r.customer_id, count(*) as bts_rentals
from rental r
join inventory i using (inventory_id)
join bts         using (film_id)
group by r.customer_id
order by bts_rentals desc;

-- …и подзапрос. Планы одинаковые: с PostgreSQL 12 CTE без побочных эффектов встраивается в запрос.
select r.customer_id, count(*) as bts_rentals
from (select film_id from film where special_features @> array['Behind the Scenes']) bts
join inventory i using (film_id)
join rental r    using (inventory_id)
group by r.customer_id
order by bts_rentals desc;

-- Как часто встречается каждый спецматериал
select feature, count(*) as films
from film, unnest(special_features) as feature
group by feature
order by films desc;

-- Позиция элемента и склейка массивов
select title,
       cardinality(special_features)                 as n_features,
       array_position(special_features, 'Trailers')  as trailers_pos,
       special_features || array['Director commentary'] as extended
from film
limit 10;

-- Первая продажа каждого сотрудника
with ranked as (
    select *, rank() over (partition by staff_id order by payment_date) as rn
    from payment
)
select staff_id, payment_id, customer_id, amount, payment_date
from ranked
where rn = 1;

-- JSON: заказы с вложенным объектом
create temp table orders (
    id   serial primary key,
    info json not null
);

insert into orders (info) values
    ('{"customer": "John Doe",     "items": {"product": "Beer",      "qty": 6}}'),
    ('{"customer": "Lily Bush",    "items": {"product": "Diaper",    "qty": 24}}'),
    ('{"customer": "Josh William", "items": {"product": "Toy Car",   "qty": 1}}'),
    ('{"customer": "Mary Clark",   "items": {"product": "Toy Train", "qty": 2}}'),
    ('{"customer": "Broken Row",   "items": {"product": "teddy",     "qty": "1fgdfgh"}}');

-- -> возвращает json, ->> возвращает text
select info -> 'customer' as as_json, pg_typeof(info -> 'customer'),
       info ->> 'customer' as as_text
from orders;

-- Кто купил ровно 2 штуки (строки с мусором в qty пропускаем)
select info ->> 'customer'
from orders
where info -> 'items' ->> 'qty' ~ '^[0-9]+$'
  and (info -> 'items' ->> 'qty')::int = 2;

-- Всего единиц товара и среднее по товарам на «Toy»
select sum((info -> 'items' ->> 'qty')::numeric) as total_qty
from orders
where info -> 'items' ->> 'qty' ~ '^[0-9.]+$';

select avg((info -> 'items' ->> 'qty')::numeric) as avg_toy_qty
from orders
where info -> 'items' ->> 'product' like 'Toy%'
  and info -> 'items' ->> 'qty' ~ '^[0-9.]+$';
