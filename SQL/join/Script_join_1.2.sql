with orders_counts as (                                 /* временная таблица для подсчета кол-ва заказов покупателя */
select customer_id, count(order_id) as order_count
from orders
group by customer_id
) 
select customer_id, order_count, avg(timestamptz(shipment_date) - timestamptz(order_date)) as w_time, sum(order_ammount) as total_summ
from orders_counts join orders using(customer_id)                      /* сожединение врменной таблицы с таблицей orders */
where order_count = (select max(order_count) from orders_counts)       /* поиск покупателей с наибольшем к-вом заказов */
group by customer_id, order_count
order by total_summ desc;                                              /* сортировка в порядке убывания суммы заказов */

/* Т.к. у товаров, помеченных 'cancelled', присутствует дата доставки, расчет проведен исходя из того, что эти заказы были
  доставлены, но покупатель от него отказался;
  общая сумма считается суммарно для полученных и отмененных заказов  */
