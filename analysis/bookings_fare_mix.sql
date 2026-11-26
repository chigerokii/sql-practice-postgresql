-- Классы обслуживания: доля кресел, доля проданных перелётов и доля выручки
with seat_share as (
    select fare_conditions, count(*) as seats
    from seats
    group by fare_conditions
),
sales as (
    select fare_conditions, count(*) as segments, sum(amount) as revenue
    from ticket_flights
    group by fare_conditions
)
select fare_conditions,
       round(100.0 * s.seats    / sum(s.seats)    over (), 1) as seats_pct,
       round(100.0 * x.segments / sum(x.segments) over (), 1) as segments_pct,
       round(100.0 * x.revenue  / sum(x.revenue)  over (), 1) as revenue_pct,
       round(x.revenue / x.segments)                          as avg_fare
from seat_share s
join sales x using (fare_conditions)
order by avg_fare desc;
