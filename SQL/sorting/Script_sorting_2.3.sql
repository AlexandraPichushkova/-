select seller_id, concat(min(category), '-', max(category)) as category_pair  -- соединяем категории через "-"
from sellers
group by seller_id                                                -- общую вырочку и кол-во категорий товаров вычисляем для каждого продавца отдельно
having extract( year from (min(date_reg::date))) = 2022           -- проверка на год регистрации
	and count(category) = 2 
	and sum(revenue) > 75000
	
/* Дату регистрации продавца определяем как наименьшую из дат регистрации каждого продавца */	