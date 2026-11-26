-- Фильтрация, сортировка, агрегаты, GROUPING SETS

-- 10 последних платежей
select *
from payment
order by payment_date desc
limit 10;

-- Три фильма с самым длинным описанием
select title, char_length(description) as description_len
from film
order by description_len desc
limit 3;

-- Первая аренда каждого покупателя
select customer_id, min(rental_date) as first_rental
from rental
group by customer_id
order by first_rental;

-- Покупатели с самым коротким логином почты: топ-5 и следующая страница
select customer_id, email
from customer
order by char_length(split_part(email, '@', 1)), customer_id
limit 5;

select customer_id, email
from customer
order by char_length(split_part(email, '@', 1)), customer_id
limit 5 offset 10;

-- Имя содержит 'jam' без учёта регистра
select first_name || ' ' || last_name as full_name
from customer
where first_name || ' ' || last_name ilike '%jam%';

-- Города на L…a без пробелов
select distinct city
from city
where city like 'L%a' and city not like '% %';

-- Активные покупатели KELLY или WILLIE
select lower(first_name || ' ' || last_name) as full_name
from customer
where activebool and first_name in ('KELLY', 'WILLIE');

-- R до 3.00 включительно или PG-13 от 4.00
select title, rating, rental_rate
from film
where (rating = 'R' and rental_rate between 0 and 3)
   or (rating = 'PG-13' and rental_rate >= 4);

-- Не вернули фильм / вернули
select count(*) filter (where return_date is null)     as not_returned,
       count(*) filter (where return_date is not null) as returned
from rental;

-- Аренды дольше 5 дней
select rental_id, customer_id, return_date - rental_date as rental_length
from rental
where return_date - rental_date > interval '5 days';

-- Новые покупатели по месяцам
select date_trunc('month', create_date) as month, count(*) as new_customers
from customer
group by 1
order by 1;

-- Метрики по покупателю
select customer_id,
       count(payment_id)     as payments,
       round(sum(amount), 0) as total,
       min(amount)           as min_payment,
       max(amount)           as max_payment
from payment
group by customer_id
order by total desc;

-- Сколько PG-фильмов по языку и цене, по языку, по цене — одним запросом
select language_id, rental_rate, count(film_id) as films
from film
where rating::text like '%PG%'
group by grouping sets ((language_id, rental_rate), (language_id), (rental_rate))
order by 1, 2;

-- Премия продавцу при числе продаж > 7300
select staff_id,
       count(payment_id) as sales,
       case when count(payment_id) > 7300 then 'Да' else 'Нет' end as bonus
from payment
group by staff_id;

-- Однофамильцы среди актёров
select last_name,
       count(*) as actors,
       initcap(string_agg(first_name, ', ' order by first_name)) as first_names
from actor
group by last_name
having count(*) > 1
order by actors desc, last_name;
