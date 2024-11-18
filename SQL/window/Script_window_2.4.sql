select date, shopnumber, category,
	case when (date-prev_date) > 1 then Null             --если предыдущая дата найдена неверно, то в данной категории и направлении товара за пред. дату не было покупок и она равна Null
		 when (date-prev_date) = 1 then prev_sales
	end as prev_sales                                    --проверка на правильность нахождения предыдущей даты
	from(
	select distinct pd.date, pd.shopnumber, pd.category, cur_sales, prev_sales, prev_date   
	from(
		select distinct date, shopnumber, category, cur_sales,  --нахожу сумму продаж за предыдущую дату (неточности: на этом этапе 2016-01-01 считается предыдущей для 2016-01-03 при отсутствии 2016-01-02 в группироке)
			lag(cur_sales) over (partition by shopnumber, category order by date) as prev_sales
		from(
			select distinct date, shopnumber, category, cur_sales
				from(
					select distinct date, shopnumber, category, price, qty,    --считаю сумму продаж по текущей дате, магазину, направлению товара
						sum(price*qty) over(partition by shopnumber, category, date) as cur_sales
					from sales join goods using(id_good) join shops using(shopnumber)
					where city='СПб'
			)
	)) as cs
	join(
	select date, shopnumber, category,
				lag(date) over (partition by shopnumber, category order by date) as prev_date  --нахожу предыдущую дату (неточности: на этом этапе 2016-01-01 считается предыдущей для 2016-01-03 при отсутствии 2016-01-02 в группироке)
			from(
				select distinct date, shopnumber, category      --отбираю только магазины Спб
				from sales join goods using(id_good) join shops using(shopnumber)
				where city='СПб'
		    )
    ) as pd on cs.date=pd.date and cs.category=pd.category and cs.shopnumber=pd.shopnumber
	)    

/* т.к. необходимо вывести сумму продаж за предыдущую дату для каждого магазина и товарного направления, то за 
 2016-01-01 всегда будет выводиться Null, т.к. это самая рання дата покупок в таблице; если в конкретном магазине
 по конкретному направлению в предыдущий день не было сделано покупок - тоже будет выводиться Null; в остальных
 случаях выполнится требуемый подсчет суммы продаж*/