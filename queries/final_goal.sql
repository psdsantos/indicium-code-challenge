-- shows the orders and its details
SELECT * FROM order_details  od
JOIN orders o ON o.order_id = od.order_id;
