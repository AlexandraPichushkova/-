select date, shopnumber, id_good 
from(
select date, shopnumber, id_good,
		row_number() over(partition by date, shopnumber order by qty desc) as row_id   --нумерую строки на каждую дату и магазин по убыванию кол-ва продаж товара, 
	from sales                                                                         -- так что у более продаваемых товаров более маленький id
)
where row_id < 4                 --на каждую дату и магазин выбираю по три топ-товара 
