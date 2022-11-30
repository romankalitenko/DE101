create schema dw;



--GEO

--creating table
drop table if exists dw.geo;
CREATE TABLE dw.geo
(
 geo_id      serial NOT null PRIMARY KEY,
 country     varchar(20) NOT NULL,
 city        varchar(20) NOT NULL,
 state	  	 varchar(20) NOT NULL,
 region      varchar(20) NOT NULL,
 postal_code varchar(20) NULL
);

--deleting rows
truncate table dw.geo;

--generating data
insert into dw.geo
select
	row_number () over (), country , city , state , region , postal_code
	from (select distinct country , city , state , region , postal_code  from orders) o;

--checking
select * from dw.geo;
select * from dw.geo where postal_code is null; --Burlington doesn't have postal code

--fill data missing - update postal code for Burlington, Vermont
update dw.geo 
set postal_code = '05401' where city = 'Burlington' and state = 'Vermont' and postal_code is null;
--checking
select * from dw.geo g where city = 'Burlington' ;

--update source table. Otherwise would be difficult to join later
update orders  
set postal_code = '05401' where city = 'Burlington' and state = 'Vermont' and postal_code is null;

--checking
select postal_code , count(geo_id)  from dw.geo g group by 1 ;
select * from dw.geo g where postal_code = '92024' --mistake in postal code??? two cities, one code -- no, it's fine




--SHIPPING

--creating table
drop table if exists dw.shipping;
create table dw.shipping
(
	ship_id		serial not null primary key,
	ship_mode	varchar(14) not null
);

--deleting rows
truncate table dw.shipping

--generating data
insert into dw.shipping
select row_number() over (), ship_mode from  (select distinct ship_mode from orders) o;

--checking
select * from dw.shipping;





-- USERS

--creating table
create table dw.users
(
 user_id		serial not null primary key,
 full_name		varchar(22) NOT NULL,
 role_name		varchar(10) NOT	NULL,
 customer_id	varchar(8) NOT NULL
);

--deleting rows
truncate table dw.users

--generating data
insert into dw.users
select row_number() over (), customer_name, 'customer', customer_id  from  (select distinct customer_name, customer_id from orders) o;

--checking
select * from dw.users;
select count(*) from (select distinct customer_name, customer_id from orders) o;




----TESTS

create table dw.test
(
id	serial not null primary key,
name	varchar(50) not null
);

select * from dw.test;
truncate table dw.test ;

insert into dw.test(name) values ('Roman');

insert into dw.test
select distinct
	row_number() over(),
	o.customer_name,
	now(),
	'customer'
from (select distinct  customer_name from orders limit 10) o;

select *, row_number() over()  from dw.test  where name = 'Pamela Stobb' 

ALTER TABLE dw.test  ADD COLUMN IF NOT EXISTS role_name varchar(10);

update dw.test 
set id = 101 where name = 'Roman';

update dw.test
set created_at = now() where created_at is null;

select created_at from dw.test t ;
