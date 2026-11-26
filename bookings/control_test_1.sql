-- Контрольная работа 1 по СУБД, демобаза «Авиаперевозки» (Postgres Pro, demo-small)

-- 1. Модели самолётов без бизнес-класса (anti-join через LEFT JOIN)
select array_agg(a.model) as no_business_class
from aircrafts a
left join seats s
       on s.aircraft_code = a.aircraft_code
      and s.fare_conditions = 'Business'
where s.aircraft_code is null;

-- 2. Число задержанных рейсов по направлениям
select departure_airport, arrival_airport, count(*) as delayed_flights
from flights
where status = 'Delayed'
group by departure_airport, arrival_airport
order by delayed_flights desc;

-- 3. Рейсы, на которые не продано ни одного билета
select count(*) as flights_without_tickets
from flights f
left join ticket_flights tf using (flight_id)
where tf.ticket_no is null;

-- 4. Пассажиры (по имени) с больше чем 700 перелётами и их уникальные направления
select t.passenger_name,
       array_agg(distinct f.departure_airport || ' -> ' || f.arrival_airport) as routes,
       count(*) as segments
from tickets t
join ticket_flights tf using (ticket_no)
join flights f         using (flight_id)
group by t.passenger_name
having count(*) > 700
order by segments desc;

-- 5. Вылеты из Пулково и прилёты в Домодедово одной таблицей
select 'Вылетели из Пулково' as status, count(*) as flights
from flights
where departure_airport = 'LED'
union all
select 'Приземлились в Домодедово', count(*)
from flights
where arrival_airport = 'DME';

-- 6. Аэропорты, куда 2016-11-02 прилетали, но откуда в этот день не вылетали (EXCEPT)
select arrival_airport as airport
from flights
where scheduled_arrival::date = '2016-11-02'
except
select departure_airport
from flights
where scheduled_departure::date = '2016-11-02';
