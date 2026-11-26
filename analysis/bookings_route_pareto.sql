-- Концентрация выручки по маршрутам: какая доля маршрутов даёт какую долю денег
with route_rev as (
    select f.departure_airport || '-' || f.arrival_airport as route,
           sum(tf.amount) as revenue
    from ticket_flights tf
    join flights f using (flight_id)
    group by 1
)
select route,
       revenue,
       row_number() over (order by revenue desc)                         as rank,
       count(*) over ()                                                  as routes_total,
       round(100.0 * sum(revenue) over (order by revenue desc) / sum(revenue) over (), 2) as cum_revenue_pct
from route_rev
order by revenue desc;
