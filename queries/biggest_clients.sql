
-- biggest clients by revenue
SELECT
    c.customer_id,
    c.company_name,
    SUM(od.unit_price *od.quantity * (1 - od.discount)) AS total_revenue,
	COUNT(o.order_id) AS number_of_orders,
	AVG(od.quantity) AS avg_order_size
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_details od ON o.order_id = od.order_id
GROUP BY
    c.customer_id, c.company_name
ORDER BY
    total_revenue DESC;
