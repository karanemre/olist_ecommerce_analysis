--Recency--
WITH last_invoice AS (
	SELECT
	customer_id,
	MAX(invoicedate)::date AS last_invoice_date
	FROM rfm
	WHERE customer_id IS NOT NULL AND invoicedate IS NOT NULL
	GROUP BY customer_id
)
    SELECT
	customer_id,
	(SELECT MAX(invoicedate)::date FROM rfm)-last_invoice_date AS recency
	FROM last_invoice;

--Frequency--
SELECT customer_id,
       COUNT(invoiceno) AS frequency
FROM rfm
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

--Monetary--
SELECT customer_id,
       SUM(unitprice*quantity)::numeric(6,0) AS monetary
FROM rfm
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

--RFM ANALİZİ--	
WITH last_invoice AS (
  SELECT
    customer_id,
    MAX(invoicedate)::date AS last_invoice_date
  FROM rfm
  WHERE customer_id IS NOT NULL AND invoicedate IS NOT NULL
  GROUP BY customer_id
),
recency AS (
  SELECT
    customer_id,
    (SELECT MAX(invoicedate)::date FROM rfm) - last_invoice_date AS recency
  FROM last_invoice
),
frequency AS (
  SELECT
    customer_id,
    COUNT(invoiceno) AS frequency
  FROM rfm
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
),
monetary AS (
  SELECT
    customer_id,
    SUM(unitprice * quantity)::numeric(6,0) AS monetary
  FROM rfm
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id
),
rfm_calculation AS (
  SELECT
    r.customer_id,
    r.recency,
    f.frequency,
    m.monetary
  FROM
    recency r
    JOIN frequency f ON r.customer_id = f.customer_id
    JOIN monetary m ON r.customer_id = m.customer_id
),
rfm_groups AS (
  SELECT 
    customer_id,
    recency,
    ntile(5) OVER (ORDER BY recency) AS recency_score,
    frequency,
    ntile(5) OVER (ORDER BY frequency DESC) AS frequency_score,
    monetary,
    ntile(5) OVER (ORDER BY monetary DESC) AS monetary_score
  FROM rfm_calculation
),
rfm_scores AS (
  SELECT 
    *,
    CONCAT(recency_score, frequency_score, monetary_score)::integer AS rfm_scores
  FROM rfm_groups
)
SELECT
  *,
  CASE
    WHEN rfm_scores <= 111 OR rfm_scores <= 222 THEN 'Champions'
    WHEN rfm_scores <= 222 OR rfm_scores <= 333 THEN 'Potential Loyalists'
    WHEN rfm_scores <= 333 OR rfm_scores <= 444 THEN 'New Customers'
    WHEN rfm_scores <= 444 OR rfm_scores <= 555 THEN 'At Risk Customers'
    ELSE 'Can’t Lose Them'
  END AS customer_segments
FROM rfm_scores;

--------------------
SELECT customer_id, 
	   rfm_recency*100 + rfm_frequency*10 + rfm_monetary AS rfm_combined 
FROM (
      SELECT customer_id, 
             NTILE(5) OVER (ORDER BY last_order_date) AS rfm_recency,
             NTILE(5) OVER (ORDER BY count_order) AS rfm_frequency,
             NTILE(5) OVER (ORDER BY totalprice) AS rfm_monetary
      FROM (
            SELECT customer_id,
                   MAX(invoicedate) AS last_order_date,
                   COUNT(*) AS count_order,
                   SUM(unitprice*quantity) AS totalprice
            FROM rfm
            WHERE invoiceno NOT LIKE '%C%'
            AND customer_id IS NOT NULL
            AND unitprice != 0
            GROUP BY customer_id
           ) AS rfm
      ) AS final_rfm












