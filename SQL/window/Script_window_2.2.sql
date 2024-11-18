select  date, city,
	(sum(price*qty) over (partition by date, city)::numeric/sum(price*qty) over (partition by date)::numeric)
		as sum_sales_rel
from goods join sales using(id_good) join shops using(shopnumber)
where category='ЧИСТОТА'


/* расчет проведен для нахождения доли продаж по дате и городу от суммарных продаж по дате */
