CREATE OR REPLACE VIEW public.orders_view AS
SELECT
  o.id AS order_id,
  o.order_date,
  o.status,
  o.comments,
  c.id AS customer_id,
  c.full_name AS customer_name,
  SUM(oi.qty * oi.unit_price) AS total_amount,
  COUNT(*) AS items_count
FROM customer_order o
JOIN customer c ON c.id = o.customer_id
JOIN order_item oi ON oi.order_id = o.id
GROUP BY o.id, o.order_date, o.status, o.comments, c.id, c.full_name;
