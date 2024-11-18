with long_time_orders as (                                                       /* временная таблица для клиентов с задержкой заказа */
	select customer_id, count(customer_id) as long_time_count
	from(
		select customer_id, timestamptz(shipment_date) - timestamptz(order_date) as w_time, order_ammount  as long_time_ammount
		from orders
		where
		EXTRACT(DAY FROM(timestamptz(shipment_date) - timestamptz(order_date)))>5    /* проверка на задержку > 5 дней */
	)
	group by customer_id),
cancelled_orders as(                                                             /* врмеенная таблица для клиентов с отмененными заказами */
	select customer_id, count(customer_id) as cancelled_count
	from(
		select customer_id
		from orders
		where order_status = 'Cancel'
	)
	group by customer_id),
tot_summ as(                                                                   /* временная таблица для общей суммы заказов клиента */
	select customer_id, sum(order_ammount) as total_summ                           
	from orders
	group by customer_id)
select name, long_time_count, cancelled_count, total_summ
from(
		select customer_id,
				name,
				coalesce(long_time_count, 0) as long_time_count,      /* функция для возвращения 0 вместо null, если задержек заказа не было */
				coalesce(cancelled_count, 0) as cancelled_count,      /* функция для возвращения 0 вместо null, если отмены заказа не было */
				total_summ
		from long_time_orders full outer join cancelled_orders using(customer_id) join customers using(customer_id)  
		join tot_summ using(customer_id)
		group by customer_id, name, long_time_count, cancelled_count, total_summ
);

/* Т.к. у товаров, помеченных 'cancelled', присутствует дата доставки, расчет проведен исходя из того, что эти заказы были
  доставлены, но покупатель от него отказался;
  общая сумма считается суммарно для полученных и отмененных заказов  */
