CREATE OR REPLACE VIEW public.recipe_cost_view AS
WITH rm_min_cost AS (
  SELECT
    s.raw_material_id,
    MIN(s.cost_numeric) AS min_cost
  FROM supply s
  GROUP BY s.raw_material_id
)
SELECT
  r.id AS recipe_id,
  r.name AS recipe_name,
  COALESCE(SUM(ri.qty * COALESCE(mc.min_cost, 0)), 0) AS estimated_cost
FROM recipe r
LEFT JOIN recipe_ingredient ri ON ri.recipe_id = r.id
LEFT JOIN rm_min_cost mc ON mc.raw_material_id = ri.raw_material_id
GROUP BY r.id, r.name;
