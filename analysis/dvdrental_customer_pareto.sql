-- Кривая концентрации выручки по покупателям
with per_customer as (
    select customer_id, sum(amount) as revenue, count(*) as payments
    from payment
    group by customer_id
)
select customer_id,
       revenue,
       payments,
       row_number() over (order by revenue desc) as rank,
       count(*) over ()                          as customers_total,
       round(100.0 * sum(revenue) over (order by revenue desc, customer_id) / sum(revenue) over (), 3) as cum_revenue_pct
from per_customer
order by revenue desc;
