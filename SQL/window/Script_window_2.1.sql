select distinct shopnumber, city, address,
	sum(qty) over (partition by shopnumber)	as sum_qty,             --считаем суммарное кол-во товаров для каждого магазина
	sum(price*qty) over (partition by shopnumber) as sum_qty_price  --считаем сумму от продаж всех товаров для каждого магазина
from goods join sales using(id_good) join shops using(shopnumber)
where date = '2016-01-02'
