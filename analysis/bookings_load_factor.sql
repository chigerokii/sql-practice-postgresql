-- Заполняемость по моделям самолётов: посадочные талоны / кресла на завершённых рейсах
with seat_counts as (
    select aircraft_code, count(*) as seats
    from seats
    group by aircraft_code
),
boarded as (
    select flight_id, count(*) as passengers
    from boarding_passes
    group by flight_id
)
select a.model,
       count(*)                                                 as flights,
       s.seats,
       round(avg(coalesce(b.passengers, 0)), 1)                 as avg_passengers,
       round(100.0 * sum(coalesce(b.passengers, 0)) / sum(s.seats), 1) as load_factor_pct
from flights f
join aircrafts a    using (aircraft_code)
join seat_counts s  using (aircraft_code)
left join boarded b using (flight_id)
where f.status = 'Arrived'
group by a.model, s.seats
order by load_factor_pct desc;
