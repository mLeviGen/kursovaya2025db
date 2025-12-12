CREATE OR REPLACE VIEW public.batches_quality_view AS
WITH last_test AS (
  SELECT DISTINCT ON (qt.batch_id)
    qt.batch_id,
    qt.test_date,
    qt.ph,
    qt.moisture_pct,
    qt.micro_bio,
    qt.status AS test_status,
    qt.inspector_id
  FROM quality_test qt
  ORDER BY qt.batch_id, qt.test_date DESC
)
SELECT
  b.id AS batch_id,
  b.code AS batch_code,
  b.prod_date,
  b.best_before,
  b.qty_kg,
  b.status AS batch_status,
  p.id AS product_id,
  p.name AS product_name,
  p.cheese_type,
  lt.test_date,
  lt.ph,
  lt.moisture_pct,
  lt.micro_bio,
  lt.test_status,
  (e.first_name || ' ' || e.last_name) AS inspector_name
FROM batch b
JOIN cheese_product p ON p.id = b.product_id
LEFT JOIN last_test lt ON lt.batch_id = b.id
LEFT JOIN employee e ON e.id = lt.inspector_id;
