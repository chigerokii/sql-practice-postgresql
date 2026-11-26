-- За сколько дней до вылета бронируют и сколько платят (эконом, один и тот же маршрут не фиксируем)
with segs as (
    select tf.fare_conditions,
           tf.amount,
           extract(day from f.scheduled_departure - b.book_date)::int as days_before
    from ticket_flights tf
    join flights f  using (flight_id)
    join tickets t  using (ticket_no)
    join bookings b using (book_ref)
)
select fare_conditions,
       width_bucket(days_before, 0, 60, 12) as bucket,
       min(days_before) as from_day,
       max(days_before) as to_day,
       count(*)         as segments,
       round(avg(amount)) as avg_amount
from segs
where days_before between 0 and 59
group by 1, 2
order by 1, 2;
