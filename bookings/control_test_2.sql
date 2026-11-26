-- Контрольная работа 2 по СУБД, демобаза «Авиаперевозки» (Postgres Pro, demo-small)

-- 1. Изменение суммы бронирований месяц к месяцу, %
with monthly as (
    select date_trunc('month', book_date)::date as month,
           sum(total_amount) as total
    from bookings
    group by 1
)
select month,
       total,
       round(100 * (total - lag(total) over (order by month)) / lag(total) over (order by month), 2) as mom_pct
from monthly
order by month;

-- 2. Пассажиры по коду мобильного оператора (три цифры после +7), JSONB
select substring(contact_data ->> 'phone', 3, 3) as operator_code,
       count(*) as passengers
from tickets
group by 1
order by 2 desc;

-- 3. Доля перелётов по маршрутам от общего числа, с названиями аэропортов
select dep.airport_name || ' – ' || arr.airport_name as route,
       count(*) as flights,
       round(100.0 * count(*) / sum(count(*)) over (), 2) as share_pct
from flights f
join airports dep on dep.airport_code = f.departure_airport
join airports arr on arr.airport_code = f.arrival_airport
group by dep.airport_name, arr.airport_name
order by flights desc;

-- 4. Для каждого рейса: кто забронировал первым, кто последним и разница во времени
with ranked as (
    select tf.flight_id, t.passenger_name, b.book_date,
           row_number() over (partition by tf.flight_id order by b.book_date)      as first_n,
           row_number() over (partition by tf.flight_id order by b.book_date desc) as last_n
    from bookings b
    join tickets t         using (book_ref)
    join ticket_flights tf using (ticket_no)
)
select flight_id,
       max(passenger_name) filter (where first_n = 1) as first_passenger,
       max(book_date)      filter (where first_n = 1) as first_booking,
       max(passenger_name) filter (where last_n = 1)  as last_passenger,
       max(book_date)      filter (where last_n = 1)  as last_booking,
       max(book_date) filter (where last_n = 1) - max(book_date) filter (where first_n = 1) as gap
from ranked
group by flight_id
order by flight_id;

-- 5. Нарастающий итог пустых мест по аэропорту и дню.
--    Берём только вылетевшие рейсы без единого посадочного талона
--    и только дни, когда из аэропорта ушло больше одного такого рейса.
with empty_flights as (
    select f.flight_id, f.departure_airport, f.actual_departure::date as day, f.aircraft_code
    from flights f
    where f.status in ('Departed', 'Arrived')
      and not exists (select 1 from boarding_passes bp where bp.flight_id = f.flight_id)
),
seat_counts as (
    select aircraft_code, count(*) as seats
    from seats
    group by aircraft_code
),
per_day as (
    select e.departure_airport, e.day,
           count(*)     as empty_flights,
           sum(s.seats) as empty_seats
    from empty_flights e
    join seat_counts s using (aircraft_code)
    group by e.departure_airport, e.day
    having count(*) > 1
)
select departure_airport, day, empty_flights, empty_seats,
       sum(empty_seats) over (partition by departure_airport order by day) as running_total
from per_day
order by departure_airport, day;
