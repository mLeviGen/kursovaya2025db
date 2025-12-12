CREATE OR REPLACE VIEW public.products_view AS
SELECT
  p.id,
  p.name,
  p.cheese_type,
  p.aging_days,
  p.base_price,
  p.is_active,
  r.name AS recipe_name
FROM cheese_product p
LEFT JOIN recipe r ON r.id = p.recipe_id;
