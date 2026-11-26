# SQL: PostgreSQL на учебных базах

Мои решения по курсу «Системы управления базами данных» (СПбГЭУ, 7 семестр, 2025). Плюс несколько аналитических запросов
поверх тех же баз: по ним построены графики ниже.
Всё прогоняется в GitHub Actions на настоящих базах: [run-sql.yml](.github/workflows/run-sql.yml) поднимает PostgreSQL 18,
загружает [Pagila](https://github.com/devrimgunduz/pagila) (DVD rental) и демобазу Postgres Pro «Авиаперевозки»,
выполняет каждый файл с `ON_ERROR_STOP` и сохраняет результаты аналитических запросов в [`results/`](results).

## Что где

| Файл | Темы |
|---|---|
| [`dvdrental/01_ddl_constraints.sql`](dvdrental/01_ddl_constraints.sql) | проектирование схемы: справочники, связи M:N, PK/FK, UNIQUE, CHECK, DEFAULT, `unnest` для вставки |
| [`dvdrental/02_filtering_sorting_grouping.sql`](dvdrental/02_filtering_sorting_grouping.sql) | фильтры, `ILIKE`, интервалы, `FILTER`, `GROUPING SETS`, `string_agg` |
| [`dvdrental/03_joins.sql`](dvdrental/03_joins.sql) | inner/left/right/cross join, anti-join |
| [`dvdrental/04_subqueries_explain.sql`](dvdrental/04_subqueries_explain.sql) | подзапросы, коррелированные подзапросы, `NOT IN` против `NOT EXISTS`, `EXPLAIN ANALYZE` |
| [`dvdrental/05_cte_recursive.sql`](dvdrental/05_cte_recursive.sql) | CTE, рекурсивный обход дерева с путём и уровнем, генерация календаря |
| [`dvdrental/06_window_functions.sql`](dvdrental/06_window_functions.sql) | `row_number`/`rank`/`dense_rank`, `lag`/`lead`, `first_value`/`last_value` с рамкой, нарастающие итоги, именованные окна |
| [`dvdrental/07_arrays_json.sql`](dvdrental/07_arrays_json.sql) | массивы (`&&`, `@>`, `ANY`, `unnest`), JSON (`->`, `->>`, проверка типов регуляркой) |
| [`bookings/control_test_1.sql`](bookings/control_test_1.sql) | контрольная 1: anti-join, `EXCEPT`, `UNION ALL`, `array_agg(distinct …)` |
| [`bookings/control_test_2.sql`](bookings/control_test_2.sql) | контрольная 2: MoM через `lag`, JSONB, доли через окно, первый и последний бронирующий на рейсе, нарастающий итог пустых мест |
| [`analysis/`](analysis) | аналитические запросы для графиков ниже |

Пример из контрольной 2: для каждого рейса найти первого и последнего забронировавшего пассажира и разрыв между ними.
Это делается одним проходом: два `row_number` в разные стороны и условная агрегация.

```sql
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
       max(passenger_name) filter (where last_n = 1)  as last_passenger,
       max(book_date) filter (where last_n = 1) - max(book_date) filter (where first_n = 1) as gap
from ranked
group by flight_id;
```

<!-- RESULTS -->

## Как запустить у себя

```bash
git clone https://github.com/devrimgunduz/pagila && createdb dvdrental
psql -d dvdrental -f pagila/pagila-schema.sql && psql -d dvdrental -f pagila/pagila-data.sql
psql -d dvdrental -f dvdrental/06_window_functions.sql
```

В Pagila даты сдвинуты относительно классической dvdrental (2022 год вместо 2005-го). Поэтому запросы
с конкретными датами из заданий я переписал на «первый месяц данных» и «самый загруженный день».

---

**EN.** PostgreSQL solutions from my university DBMS course (DVD rental / Pagila and the Postgres Pro airline demo DB):
DDL and constraints, joins, subqueries and `EXPLAIN ANALYZE`, CTEs and recursive queries, window functions, arrays and JSON.
A GitHub Actions workflow loads both databases, runs every file, and stores the analysis query results that feed the charts.
