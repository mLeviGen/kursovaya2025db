CREATE OR REPLACE VIEW public.catalog_view AS
SELECT
  id, name, cheese_type, aging_days, base_price, is_active,
  (base_price * 0.90)::numeric(10,2) AS b2b_price_from_10
FROM cheese_product
WHERE is_active = true;
