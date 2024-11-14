select city, count(*) as client_count,
	case when age < 21 then 'young'                  /* вычисляем возрастную категорию */
	      when age > 20 and age < 50 then 'adult'
	      when age > 49 then 'old'
	end as age_group
from users
group by city, age_group                             /* группируем по возрастным категориям */
order by city, client_count desc                     /* сортируем по убыванию по кол-ву покупателей в каждой категории */