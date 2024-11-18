select seller_id, 
  floor(extract( day from (current_timestamp-min(date_reg::date)))/30) as month_from_registration, -- кол-во полных месяцев с даты регистрации продавца
  max(delivery_days)-min(delivery_days) as max_delivery_difference    -- разница между макс. и мин. сроком доставки
from sellers 
where category != 'Bedding'                                     -- категорию "Bedding" не учитываем
group by seller_id                                              -- общую вырочку и кол-во категорий товаров вычисляем для каждого продавца отдельно
having count(category) > 1                                      -- условие для неуспешных продавцов
	and sum(revenue) <= 50000 
order by seller_id                                              -- вывод результатов по возрастанию id продавцов

/* Дату регистрации продавца определяем как наименьшую из дат регистрации каждого продавца */