-- Оконные функции

-- Доля каждого покупателя в общей выручке (окно поверх агрегата)
select customer_id,
       sum(amount) as total,
       round(100 * sum(amount) / sum(sum(amount)) over (), 3) as share_pct
from payment
group by customer_id
order by total desc;

-- Фильм, актёр и сколько всего фильмов у актёра
select f.title,
       a.first_name || ' ' || a.last_name as actor,
       count(*) over (partition by a.actor_id) as actor_films
from film f
join film_actor fa using (film_id)
join actor a       using (actor_id)
order by f.title, actor;

-- Текущий и предыдущий фильм каждого покупателя
select c.first_name || ' ' || c.last_name as customer,
       r.rental_date,
       f.title,
       lag(f.title) over (partition by r.customer_id order by r.rental_date) as previous_title
from rental r
join customer c  using (customer_id)
join inventory i using (inventory_id)
join film f      using (film_id);

-- Последняя оплата каждого покупателя
select distinct
       c.first_name || ' ' || c.last_name as customer,
       first_value(p.payment_date) over w as last_payment_date,
       first_value(p.amount)       over w as last_payment_amount
from payment p
join customer c using (customer_id)
window w as (partition by p.customer_id order by p.payment_date desc);

-- Пятый фильм, который взял каждый покупатель
with numbered as (
    select customer_id, inventory_id,
           row_number() over (partition by customer_id order by rental_date) as n
    from rental
)
select c.first_name || ' ' || c.last_name as customer, f.title
from numbered nr
join customer c  using (customer_id)
join inventory i using (inventory_id)
join film f      using (film_id)
where nr.n = 5;

-- Первая и последняя аренда каждого покупателя
select distinct customer_id,
       first_value(rental_date) over w as first_rental,
       last_value(rental_date)  over w as last_rental
from rental
window w as (partition by customer_id order by rental_date
             rows between unbounded preceding and unbounded following)
order by customer_id;

-- Нарастающий итог продаж каждого сотрудника по дням (первый месяц данных)
with first_month as (
    select date_trunc('month', min(payment_date)) as m from payment
)
select s.first_name || ' ' || s.last_name as staff,
       p.payment_date::date as day,
       sum(p.amount) as day_total,
       sum(sum(p.amount)) over (partition by s.staff_id order by p.payment_date::date) as running_total
from payment p
join staff s using (staff_id)
where date_trunc('month', p.payment_date) = (select m from first_month)
group by s.staff_id, p.payment_date::date
order by staff, day;

-- Нумерация и нарастающий итог платежей
select payment_id,
       customer_id,
       row_number() over (order by payment_date)                               as n_all,
       row_number() over (partition by customer_id order by payment_date)      as n_customer,
       sum(amount)  over (partition by customer_id order by payment_date, amount) as running_total,
       dense_rank() over (partition by customer_id order by amount desc)       as amount_rank
from payment
order by customer_id, payment_date;

-- row_number vs rank vs dense_rank на одной дате
select customer_id, payment_date::date as day,
       row_number() over w as row_number,
       rank()       over w as rank,
       dense_rank() over w as dense_rank
from payment
window w as (partition by customer_id order by payment_date::date)
order by customer_id, day;

-- Разница со следующим платежом того же покупателя
select customer_id, payment_date, amount,
       lead(amount) over w           as next_amount,
       lead(amount) over w - amount  as diff_to_next
from payment
window w as (partition by customer_id order by payment_date);

-- Акция: каждый сотый платёж за день получает скидку
with day_payments as (
    select customer_id,
           row_number() over (order by payment_date) as n
    from payment
    where payment_date::date = (
        select payment_date::date from payment
        group by 1 order by count(*) desc limit 1   -- самый загруженный день
    )
)
select customer_id
from day_payments
where n % 100 = 0;

-- Для каждой страны: кто взял больше всего фильмов, кто больше всех заплатил, кто платил последним
with stats as (
    select co.country,
           c.first_name || ' ' || c.last_name as customer,
           count(p.payment_id) as payments,
           sum(p.amount)       as total,
           max(p.payment_date) as last_payment
    from country co
    join city ci    using (country_id)
    join address a  using (city_id)
    join customer c using (address_id)
    join payment p  using (customer_id)
    group by co.country, c.customer_id
)
select distinct country,
       first_value(customer) over (partition by country order by payments desc, customer)     as most_rentals,
       first_value(customer) over (partition by country order by total desc, customer)        as biggest_spender,
       first_value(customer) over (partition by country order by last_payment desc, customer) as latest_customer
from stats
order by country;

-- Для каждого магазина: самый загруженный день и день с минимальной выручкой
with daily as (
    select i.store_id,
           r.rental_date::date as day,
           count(*)            as rentals,
           sum(p.amount)       as revenue
    from rental r
    join payment p   using (rental_id)
    join inventory i using (inventory_id)
    group by 1, 2
),
ranked as (
    select *,
           rank() over (partition by store_id order by rentals desc, day) as r_busy,
           rank() over (partition by store_id order by revenue, day)      as r_low
    from daily
)
select b.store_id,
       b.day as busiest_day, b.rentals as max_rentals,
       l.day as weakest_day, l.revenue as min_revenue
from ranked b
join ranked l on l.store_id = b.store_id and l.r_low = 1
where b.r_busy = 1
order by b.store_id;

-- Именованные окна и FILTER внутри оконного агрегата
select customer_id, payment_date, amount,
       avg(amount) over w_customer as avg_customer,
       sum(amount) over w_customer as total_customer,
       sum(amount) filter (where amount < 5) over w_customer as total_small_payments,
       avg(amount) over () as avg_all
from payment
window w_customer as (partition by customer_id);
