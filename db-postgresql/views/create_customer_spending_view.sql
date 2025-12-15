CREATE OR REPLACE VIEW public.customer_spending_view AS
SELECT
  c.id AS customer_id,
  c.full_name,
  c.email,
  COUNT(DISTINCT o.id) AS orders_count,
  COALESCE(SUM(oi.qty * oi.unit_price), 0) AS total_spent
FROM customer c
LEFT JOIN customer_order o ON o.customer_id = c.id
LEFT JOIN order_item oi ON oi.order_id = o.id
GROUP BY c.id, c.full_name, c.email;
