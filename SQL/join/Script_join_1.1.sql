with wait_time as (                                                                         /* временная таблица с временем ожидания доставки */
	select customer_id, (timestamptz(shipment_date) - timestamptz(order_date)) as w_time    /* явное приведение к типу данных timestamptz */
	from orders                                                      
)
select distinct customer_id, name, w_time from 
wait_time join customers using (customer_id)                   /* сожединение врменной таблицы с таблицей customers */
where w_time = (select max(w_time) from wait_time);            /* нахождение максимального времени ожидания */

/* Т.к. у товаров, помеченных 'cancelled', присутствует дата доставки, расчет проведен исходя из того, что эти заказы были
  доставлены, но покупатель от него отказался;
  В таблице представлены все клиенты, время ожидания которых максимально, т.к. время ожидания у них совпадает до секунд */