CREATE OR REPLACE VIEW public.product_sales_view AS
SELECT
  p.id AS product_id,
  p.name AS product_name,
  p.cheese_type,
  COUNT(DISTINCT oi.order_id) AS orders_count,
  COALESCE(SUM(oi.qty), 0) AS total_qty,
  COALESCE(SUM(oi.qty * oi.unit_price), 0) AS revenue
FROM cheese_product p
LEFT JOIN order_item oi ON oi.product_id = p.id
GROUP BY p.id, p.name, p.cheese_type;
