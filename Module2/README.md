
# Модуль 2

## Установка БД

Установил базу PostgreSQL 15.

## Загрузка данных в БД

Данные загружены через запросы DBeaver - использовал готовые скрипты, таблицы [orders](data_upload_sql/orders.sql), [people](data_upload_sql/people.sql), [returns](/data_upload_sql/returns.sql).

В принципе можно было бы сделать это проще (чтобы не писать команды `insert into`):
- Вариант 1 - вкладки из Sample.xls сохранить в CSV. Создать сами таблицы через клиент или командную строку и далее `COPY orders FROM '/path/... orders.csv' DELIMITER ',' CSV HEADER
`
- Вариант 2 - тот же CSV импортировать через функцию `Импорт данных` в DBeaver или PgAdmin

## SQL запросы

1. Суммы продаж по штатам, где кол-во заказов > 10
```sql
select distinct
	state ,
	count(order_id) as orders,
	sum(sales) as rev
from orders
group by 1
having count(order_id) > 10
order by rev desc;
```

2. Упущенная выгода - сумма возвратов
```sql
select
	sum(sales)
from orders o
inner join (select distinct order_id from returns) as dr on dr.order_id = o.order_id ;
```

3. Ранжирование сэйлзов
```sql
select
	p.person as Salesman,
	count(order_id) as Orders,
	sum(sales) as Sales,
	sum(profit) as Profit
from orders o
left join people p on p.region = o.region
group by 1
order by 4 desc
```

## Нарисовать модель данных в SQLdbm

![](Pics/data_model_physical_v3.png)

Я внес изменения в структуру данных:
1. Фиксацию факта продаж я разделил на две сущности - сами заказы `orders.order_id` и позиции внутри заказа `orders_items.item_id`. На случай, если магазин позволяет вносить изменения внутри заказа или комплектность заказа может поменяться. Тогда эти изменения проще будет отражать в такой структуре.
2. Выделил скидки в отдельную таблицу `discounts` и добавил поле `description` - каждая скидка должна чем то объяснятся. В идеале, зависимости от источника скидок, должны быть еще связанные таблицы: например, для учета промокодов, акций, скидок по системе лояльности и пр.
3. Возвраты внесены в таблицу `item_status`. Она не просто так называется не Returns - возвраты только одна из причин отмены отдельной позиции, позже можно будет использовать таблицы item_status, чтобы учесть их все. Правильно привязать таблицу к `items`, а не `orders`, так как отменяться могут отдельные позиции, а не весь заказ. Хоть в нашем сэмпле данные есть только по привязке по номеру заказа, немного поменял это в своей структуре.

[СКРИПТ](from_public_to_dw.sql) под описанную модель данных. Таблицы новой модели данных созданы в отдельной схеме `dw`.

## Нарисовать графики в Google Sheets

## Нарисовать графики в KlipFolio
