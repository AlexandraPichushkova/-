/* Выведите список сотрудников с именами сотрудников, получающими самую высокую зарплату в отделе */
/* Способ реализации без оконных функций */

select s.first_name, last_name, salary, mns.industry, max_salary_name as name_highest_sal
from
	(select first_name, last_name, salary, industry                   --список всех сотрудников
	from salary
	group by first_name, last_name, salary, industry) as s
	join
	(select first_name as max_salary_name, ms.industry, max_salary    --имена сотрудников с макс. зарплатой в каждой категории
	from
		(select industry, max(salary) as max_salary                   --находим макс. зарплату в каждой индустрии
		from salary
		group by industry
		) as ms
		join(
		select first_name, industry, salary                           --список зарплат всех сотрудников в каждой индустрии
		from salary
		group by first_name, industry, salary) as ns
		on ms.industry=ns.industry and ms.max_salary=ns.salary
	) as mns
	on s.industry=mns.industry
	
	
/* Способ реализации с оконной функцией */
select first_name, last_name, salary, industry,
first_value(first_name) over(partition by industry order by salary desc) as name_highest_sal
from salary
	
	

/* Выведите список сотрудников с именами сотрудников, получающими самую низкую зарплату в отделе */
/* Способ реализации без оконных функций */
	
select s.first_name, last_name, salary, mns.industry, min_salary_name as name_lowest_sal
from
	(select first_name, last_name, salary, industry                   --список всех сотрудников
	from salary
	group by first_name, last_name, salary, industry) as s
	join
	(select first_name as min_salary_name, ms.industry, min_salary    --имена сотрудников с мин. зарплатой в каждой категории
	from
		(select industry, min(salary) as min_salary                   --находим мин. зарплату в каждой индустрии
		from salary
		group by industry
		) as ms
		join(
		select first_name, industry, salary                           --список зарплат всех сотрудников в каждой индустрии
		from salary
		group by first_name, industry, salary) as ns
		on ms.industry=ns.industry and ms.min_salary=ns.salary
	) as mns
	on s.industry=mns.industry
	
	
/* Способ реализации с оконной функцией */
select first_name, last_name, salary, industry,
	last_value(first_name) 
	over(
	partition by industry 
	order by salary desc
	range between unbounded preceding and unbounded following) as name_lowest_sal
from salary