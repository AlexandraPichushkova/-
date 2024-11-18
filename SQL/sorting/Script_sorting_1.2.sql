select category, round(AVG(price)::numeric, 2) as avg_price   /* округление средней цены до 2 знаков после запятой */
from products                                                        
where name like '%Hair%' or name like '%Home%'                /* в названияx товаров присутствуют слова 'Hair', 'Home'*/
or name like '%hair%' or name like '%home%'							                        	/* без учета регистра */
group by category                                             /* цена - средняя по категории */
