CREATE OR REPLACE VIEW public.supplies_view AS
SELECT
  s.supplier_id,
  sup.name AS supplier_name,
  s.raw_material_id,
  rm.name AS raw_material_name,
  s.cost_numeric,
  s.lead_time_days
FROM supply s
JOIN supplier sup ON sup.id = s.supplier_id
JOIN raw_material rm ON rm.id = s.raw_material_id;
