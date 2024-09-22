Case 1 : Sipariş Analizi
Question 1 : 
SELECT
    (date_trunc('month', order_approved_at))::date AS order_month,
    COUNT(*) AS order_count
FROM
    orders
WHERE order_approved_at IS NOT NULL
GROUP BY
    order_month
ORDER BY
    order_month;

Question 2 :
SELECT 
    (date_trunc('month', order_approved_at))::date AS order_month,
    COUNT(order_id) AS order_count
FROM 
    orders
WHERE 
    order_approved_at IS NOT NULL 
    AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY 
    order_month
ORDER BY 
    order_month;
	
SELECT 
    (date_trunc('month', order_approved_at))::date AS order_month,
    COUNT(order_id) AS order_count
FROM 
    orders
WHERE 
    order_approved_at IS NOT NULL 
    AND order_status IN ('canceled', 'unavailable')
GROUP BY 
    order_month
ORDER BY 
    order_month;	
			
Question 3 :
SELECT
    (date_trunc('month', order_approved_at))::date AS order_month,
	p.product_category_name,
    COUNT(*) AS order_count
FROM
    order_items AS oi
INNER JOIN
    products AS p ON p.product_id = oi.product_id
INNER JOIN
    orders AS o ON o.order_id = oi.order_id    
WHERE product_category_name IS NOT NULL AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY
    1,2
ORDER BY
    order_count DESC;

SELECT
    p.product_category_name,
    COUNT(distinct o.order_id) AS order_count
	FROM
    order_items AS oi
INNER JOIN
    products AS p ON p.product_id = oi.product_id
INNER JOIN
    orders AS o ON o.order_id = oi.order_id
WHERE
    o.order_approved_at IS NOT NULL AND p.product_category_name IS NOT NULL AND order_status NOT IN ('canceled', 'unavailable')
    AND (
        CASE
            WHEN (EXTRACT(MONTH FROM o.order_approved_at) = 5 AND EXTRACT(DAY FROM o.order_approved_at) = 12) THEN 'Anneler Günü'
            END
    ) IS NOT NULL
GROUP BY
    p.product_category_name
ORDER BY
    order_count DESC;
	
Question 4 :	
SELECT
    TO_CHAR(o.order_approved_at, 'Day') AS day_name,
    COUNT(*) AS order_count
FROM
    orders o
WHERE
    o.order_approved_at IS NOT NULL
GROUP BY
    day_name
ORDER BY
    order_count DESC;

SELECT
    EXTRACT(DAY FROM o.order_approved_at) AS day_of_month,
    COUNT(*) AS order_count
FROM
    orders o
WHERE
    o.order_approved_at IS NOT NULL
GROUP BY
    day_of_month
ORDER BY
    order_count DESC;

Case 2 : Müşteri Analizi 
Question 1 :
WITH city_and_order AS (
    SELECT
        c.customer_id,
        c.customer_city,
        COUNT(o.order_id) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY COUNT(o.order_id) DESC) AS rn
    FROM
        customers c
    LEFT JOIN
        orders o ON o.customer_id = c.customer_id
    GROUP BY
        c.customer_id, c.customer_city
),
city_of_customer AS (
    SELECT
        customer_id,
        customer_city
    FROM
        city_and_order
    WHERE
        rn = 1
)
SELECT
	cc.customer_city,
    COUNT(DISTINCT o.order_id) AS order_count
FROM
    city_of_customer cc
LEFT JOIN
    customers c ON c.customer_id = cc.customer_id
LEFT JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY
    cc.customer_city
ORDER BY
    2 DESC;

Case 3: Satıcı Analizi
Question 1 :
SELECT
    s.seller_id,
    o.order_id,
    EXTRACT(HOUR FROM o.order_delivered_customer_date - o.order_approved_at) || ' saat ' || 
    EXTRACT(MINUTE FROM o.order_delivered_customer_date - o.order_approved_at) || ' dakika' AS time_diff,
    COUNT(o.order_id) AS count_order,
    COUNT(r.review_comment_message) AS count_comment,
	ROUND(AVG(r.review_score),1) AS avg_score
FROM
    sellers AS s
INNER JOIN
    order_items AS oi ON s.seller_id = oi.seller_id
INNER JOIN
    orders AS o ON o.order_id = oi.order_id
INNER JOIN
    reviews AS r ON r.order_id = o.order_id
WHERE 
    o.order_delivered_customer_date IS NOT NULL 
    AND o.order_approved_at IS NOT NULL 
    AND o.order_delivered_customer_date > o.order_approved_at
GROUP BY 
    s.seller_id, o.order_id, o.order_delivered_customer_date, o.order_approved_at
HAVING 
    COUNT(o.order_id) > 10
ORDER BY 
    time_diff ASC
LIMIT 5;

Question 2 : 
SELECT 	
	DISTINCT s.seller_id,
	COUNT(DISTINCT p.product_category_name) as count_category,
	COUNT(DISTINCT o.order_id) as count_order
FROM sellers as s
LEFT JOIN order_items as oi
	ON oi.seller_id = s.seller_id
LEFT JOIN orders as o
	ON o.order_id = oi.order_id
LEFT JOIN products as p
	ON p.product_id = oi.product_id
WHERE p.product_category_name IS NOT NULL
GROUP by 1
ORDER BY 2 DESC, 3 ASC;

Case 4 : Payment Analizi
Question 1 :
SELECT c.customer_state,
       COUNT (c.customer_id) AS count_customer
       FROM payments AS p
 INNER JOIN orders AS o
    ON p.order_id = o.order_id
 INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
 WHERE p.payment_installments=24
 GROUP BY 1
 ORDER BY 2 DESC;

Question 2 :
SELECT p.payment_type,
COUNT(DISTINCT o.order_id) AS count_order,
SUM(p.payment_value) AS sum_payment
FROM payments AS p 
LEFT JOIN orders AS o ON p.order_id=o.order_id
WHERE order_status NOT IN ('unavailable','cancelled')
GROUP BY 1
ORDER BY count_order DESC;

Question 3 :
SELECT pr.product_category_name,
       COUNT (DISTINCT o.order_id) AS count_order
	   FROM payments AS p
 INNER JOIN order_items AS o
    ON p.order_id = o.order_id
 INNER JOIN products AS pr
    ON pr.product_id = o.product_id
 WHERE p.payment_installments=1
 GROUP BY 1
 ORDER BY 2 DESC;
 
SELECT pr.product_category_name, 
       COUNT (DISTINCT o.order_id) AS count_order
       FROM payments AS p
 INNER JOIN order_items AS o
    ON p.order_id = o.order_id
 INNER JOIN products AS pr
    ON pr.product_id = o.product_id
 WHERE p.payment_installments>=24
 GROUP BY 1
 ORDER BY 2 DESC;

