
-- average order quantity
SELECT AVG(od.quantity) AS avg_order_quantity
FROM orders o
JOIN order_details od ON o.order_id = od.order_id;
