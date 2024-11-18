SELECT 
    cs.product_category,
    cs.total_sales AS summ,
    mps.product_name AS best_product,
    mps.product_total_sales AS best_product_summ
FROM (                                                          --Вычисляет общую сумму продаж (total_sales) для каждой категории продуктов 
    SELECT product_category, SUM(order_ammount) AS total_sales
    FROM orders_2 JOIN products_3 USING(product_id)
    GROUP BY product_category
) AS cs
JOIN (
    SELECT ps.product_category, ps.product_name, ps.product_total_sales  --определяет продукт с макс. суммой продаж по каждой категории
    FROM (                                                    --Вычисляет общую сумму продаж (product_total_sales) для каждого продукта (product_name) в каждой категории 
        SELECT product_category, product_name, SUM(order_ammount) AS product_total_sales
        FROM orders_2 JOIN products_3 USING(product_id)
        GROUP BY product_category, product_name
    ) AS ps
    JOIN (                                                    --Определяет максимальную сумму продаж (max_product_total_sales) для каждой категории
        SELECT product_category, MAX(product_total_sales) AS max_product_total_sales
        FROM (
            SELECT product_category, product_name, SUM(order_ammount) AS product_total_sales
            FROM orders_2 JOIN  products_3 USING(product_id)
            GROUP BY product_category, product_name
        ) AS ps
        GROUP BY  product_category
    ) AS max_ps 
    ON ps.product_category = max_ps.product_category 
    AND ps.product_total_sales = max_ps.max_product_total_sales
) AS mps 
ON cs.product_category = mps.product_category
ORDER BY summ DESC;                                           /* сортировка, при которой первая строка результата определяет категорию продукта с
                                                                 наибольшнй общей суммой продаж */