
-- total sales revenue
SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id;
