-- Выручка по жанрам: сколько фильмов, сколько аренд, сколько денег на один фильм
select c.name as category,
       count(distinct f.film_id)                           as films,
       count(r.rental_id)                                  as rentals,
       sum(p.amount)                                       as revenue,
       round(sum(p.amount) / count(distinct f.film_id), 1) as revenue_per_film
from category c
join film_category fc using (category_id)
join film f           using (film_id)
join inventory i      using (film_id)
join rental r         using (inventory_id)
join payment p        using (rental_id)
group by c.name
order by revenue desc;
