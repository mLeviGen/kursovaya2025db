CREATE OR REPLACE VIEW public.order_items_view AS
SELECT
  oi.order_id,
  oi.product_id,
  p.name AS product_name,
  p.cheese_type,
  oi.qty,
  oi.unit_price,
  (oi.qty * oi.unit_price) AS line_total
FROM order_item oi
JOIN cheese_product p ON p.id = oi.product_id;
