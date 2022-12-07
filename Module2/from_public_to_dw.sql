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
truncate table dw.shipping;

--generating data
insert into dw.shipping
select row_number() over (), ship_mode from  (select distinct ship_mode from orders) o;

--checking
select * from dw.shipping;





--USERS

--creating table
create table dw.users
(
 user_id		serial not null primary key,
 full_name		varchar(22) NOT NULL,
 role_name		varchar(10) NOT	NULL,
 customer_id	varchar(8) NOT NULL
);

--deleting rows
truncate table dw.users;

--generating data
insert into dw.users
select row_number() over (), customer_name, 'customer', customer_id  from  (select distinct customer_name, customer_id from orders) o;

--checking
select * from dw.users;
select count(*) from (select distinct customer_name, customer_id from orders) o;





--PRODUCTS

--creating table
create table dw.products
(
 prod_id		serial not null primary key,
 product_id		varchar(15) not null,
 product_name	varchar(127) not null,
 segment		varchar(11) not null,
 category		varchar(15) not null,
 subcategory	varchar(11) not null,
 unit_price		numeric(9,4) not null
);

--deleting rows
truncate table dw.products;

--generating data
insert into dw.products
select row_number() over (), product_id , product_name , segment , category , subcategory , unit_price from  (select distinct product_id , product_name , segment , category , subcategory , sales / (1-discount) / quantity as unit_price from orders) o;

--checking
select * from dw.products;





---DISCOUNTS

--creating table
create table dw.discounts
(
 discount_id		serial not null primary key,
 discount			numeric(9,4) not null,
 description		varchar(150) null
);

--deleting rows
truncate table dw.discounts;

--generating data
insert into dw.discounts
select row_number() over (), discount from  (select distinct discount from orders) o;


--checking
select * from dw.discounts;





---METRICS

---ORDERS

--creating table
create table dw.orders
(
 order_num		serial not null primary key,
 order_id		varchar(14) not null,
 user_id		integer not null,
 ship_id		integer not null,
 geo_id			integer not null,
 order_date		date not null,
 ship_date		date not null
);

--deleting rows
truncate table dw.orders;

--generating data
insert into dw.orders
select
	row_number() over () as order_num,
	o.order_id,
	u.user_id,
	sh.ship_id,
	g.geo_id,
	o.order_date,
	o.ship_date
from (select distinct order_id, order_date , ship_date, customer_id, customer_name, ship_mode, country, city, state, region, postal_code from orders) o
inner join dw.users u on o.customer_id = u.customer_id and o.customer_name = u.full_name
inner join dw.shipping sh on o.ship_mode = sh.ship_mode 
inner join dw.geo g on o.country = g.country and o.city = g.city and o.state = g.state and o.region = g.region and o.postal_code = cast(g.postal_code as integer) --different formats: orders.postal_code is integer and geo.postal_code is varchar
;

--checking
select count(*) from (select distinct order_id from orders) o;
select count(*) from dw.orders;





---ORDERS_ITEMS

--creating table
drop table if exists dw.orders_items;
create table dw.orders_items
(
 item_id		serial not null primary key,
 discount_id	integer not null,
 order_num		integer not null,
 prod_id		integer not null,
 quantity		integer not null,
 sales			numeric(9,4) not null,
 profit			numeric(21,16) not null
);

--deleting rows
truncate table dw.orders_items;

--generating data
insert into dw.orders_items
select 
	row_number() over () as item_id,
	d.discount_id ,
	o2.order_num ,
	p.prod_id ,
	o.quantity ,
	o.sales ,
	o.profit
from orders o
inner join dw.discounts d on d.discount = o.discount 
inner join dw.orders o2 on o.order_id = o2.order_id 
inner join dw.products p on o.product_id = p.product_id and o.product_name = p.product_name and o.segment = p.segment and o.category = p.category and o.subcategory = p.subcategory 
;

--checking
select count(*) from dw.orders_items;
select count(*) from orders o ;
select * from dw.orders_items oi ;

select count(*) from dw.orders_items oi 
inner join dw.orders o on o.order_num = oi.order_num 
inner join dw.products p on p.prod_id = oi.prod_id 
inner join dw.discounts d on d.discount_id = oi.discount_id 
inner join dw.geo g on g.geo_id = o.geo_id 
inner join dw.shipping s on s.ship_id = o.ship_id 
inner join dw.users u on u.user_id = o.user_id ; --9994 rows, correct




---RETURNS

--creating table
drop table if exists dw.item_status;
create table dw.item_status
(
 item_id	integer not null primary key,
 returned	boolean not null
);

--deleting rows
truncate table dw.item_status;

--generating data
insert into dw.item_status
select distinct 
	oi.item_id , ret.status
from dw.orders_items oi 
inner join dw.orders o2 on oi.order_num = o2.order_num 
inner join 
(select distinct 
	o.order_id , case when r.returned = 'Yes' then true else false end as status
	from 
	orders o 
	left join "returns" r on r.order_id = o.order_id) ret on ret.order_id = o2.order_id
;

--checking
select * from dw.item_status;

