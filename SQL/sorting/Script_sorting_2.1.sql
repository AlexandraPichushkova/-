select seller_id, count(category) as total_categ, avg(rating) as avg_rating, sum(revenue) as total_revenue,
		case when sum(revenue) > 50000 then 'rich'                  -- опрееляем тип продавца по общей выручке
	    when sum(revenue) <= 50000 then 'poor'
	    end as seller_type
from sellers 
where category != 'Bedding'                                         -- категорию "Bedding" не учитываем
group by seller_id                                                  -- общую вырочку и средний рейтинг вычисляем для каждого продавца отдельно
having count(category) > 1                                          -- под типы продавцов подходят только те, кто продает > одной категории
order by seller_id                                                  -- вывод результатов по возрастанию id продавцов

/* Необходимо вывести только продавцов категории poor или rich; продавцы, не подходящие ни под одну из этих категорий,
   не выводятся */