-- DDL: справочники, связи многие-ко-многим, ограничения, DML
-- Всё создаётся в отдельной схеме, чтобы не трогать учебную базу.

create schema if not exists chirkov;
set search_path to chirkov;

-- Справочники: автоинкрементный PK, имя без NULL и без дублей
create table language (
    language_id serial primary key,
    name        varchar(50) not null unique
);

create table nationality (
    nationality_id serial primary key,
    name           varchar(50) not null unique
);

create table country (
    country_id serial primary key,
    name       varchar(50) not null unique
);

insert into language (name)    values ('English'), ('French'), ('Russian'), ('German'), ('Spanish');
insert into nationality (name) values ('Slavs'), ('Anglo-Saxons'), ('Franks'), ('Germans'), ('Hispanics');
insert into country (name)     values ('Russia'), ('Germany'), ('France'), ('UK'), ('Spain');

-- Таблицы связей: составной PK + два FK (как film_actor)
create table language_nationality (
    language_id    int not null references language (language_id),
    nationality_id int not null references nationality (nationality_id),
    primary key (language_id, nationality_id)
);

create table nationality_country (
    nationality_id int not null references nationality (nationality_id),
    country_id     int not null references country (country_id),
    primary key (nationality_id, country_id)
);

insert into language_nationality values (1, 2), (2, 3), (3, 1), (4, 4), (5, 5);
insert into nationality_country  values (1, 1), (2, 4), (3, 3), (4, 2), (5, 5);

-- Какой народ на каком языке говорит и где живёт
select l.name as language, n.name as nationality, c.name as country
from language_nationality ln
join language l       using (language_id)
join nationality n    using (nationality_id)
join nationality_country nc using (nationality_id)
join country c        using (country_id)
order by 1;

-- CHECK, DEFAULT, вставка из массивов через unnest
create table film_new (
    film_name        varchar(255) not null,
    film_year        int check (film_year > 0),
    film_rental_rate numeric(4, 2) default 0.99,
    film_duration    int not null check (film_duration > 0)
);

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select *
from unnest(
    array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List'],
    array[1994, 1999, 1985, 1994, 1993],
    array[2.99, 0.99, 1.99, 2.99, 3.99],
    array[142, 189, 116, 142, 195]
) as t (film_name, film_year, film_rental_rate, film_duration);

update film_new set film_rental_rate = film_rental_rate + 1.41;

delete from film_new where film_name = 'Back to the Future';

insert into film_new values ('Call Me by Your Name', 2017, 3.49, 132);

select *, round(film_duration / 60.0, 1) as duration_hours
from film_new;

drop table film_new;

reset search_path;
drop schema chirkov cascade;
