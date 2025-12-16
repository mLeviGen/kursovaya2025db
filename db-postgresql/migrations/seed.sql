INSERT INTO role(name) VALUES
  ('Technologist'),
  ('Inspector'),
  ('Manager')
ON CONFLICT DO NOTHING;

INSERT INTO employee(role_id, first_name, last_name, phone, email, hire_date)
VALUES
  ((SELECT id FROM role WHERE name='Technologist'), 'Ivan', 'Petrenko', '380000000001', 'tech@cheese.local', current_date - 200),
  ((SELECT id FROM role WHERE name='Inspector'),   'Oleh', 'Koval',    '380000000002', 'insp@cheese.local', current_date - 150),
  ((SELECT id FROM role WHERE name='Manager'),     'Anna', 'Shev',     '380000000003', 'mgr@cheese.local',  current_date - 100)
ON CONFLICT (email) DO NOTHING;

INSERT INTO supplier(name, phone, email, address, rating)
VALUES
  ('MilkFarm LLC', '380111111111', 'milk@sup.local', 'Kyiv', 5),
  ('Salt&Co',      '380222222222', 'salt@sup.local', 'Lviv', 4),
  ('CultureLab',   '380333333333', 'cult@sup.local', 'Odesa', 5)
ON CONFLICT (name) DO NOTHING;

INSERT INTO raw_material(name, unit, shelf_life_days, allergen_flag)
VALUES
  ('Milk', 'L', 7, true),
  ('Salt', 'kg', 3650, false),
  ('Rennet', 'g', 365, false),
  ('Starter culture', 'g', 365, false)
ON CONFLICT (name) DO NOTHING;

INSERT INTO supply(supplier_id, raw_material_id, cost_numeric, lead_time_days)
SELECT sup.id, rm.id, x.cost, x.lead
FROM (VALUES
  ('MilkFarm LLC','Milk', 0.80, 1),
  ('Salt&Co', 'Salt', 1.20, 2),
  ('CultureLab','Starter culture', 12.00, 3),
  ('CultureLab','Rennet', 8.00, 3)
) AS x(sup_name, rm_name, cost, lead)
JOIN supplier sup ON sup.name = x.sup_name
JOIN raw_material rm ON rm.name = x.rm_name
ON CONFLICT DO NOTHING;

INSERT INTO recipe(name, description, yield_pct, author_id)
VALUES
  ('Gouda recipe', 'Base gouda process', 90, (SELECT id FROM employee WHERE email='tech@cheese.local')),
  ('Brie recipe',  'Base brie process',  88, (SELECT id FROM employee WHERE email='tech@cheese.local'))
ON CONFLICT (name) DO NOTHING;

INSERT INTO recipe_ingredient(recipe_id, raw_material_id, qty, unit)
SELECT r.id, rm.id, x.qty, x.unit
FROM (VALUES
  ('Gouda recipe','Milk', 10, 'L'),
  ('Gouda recipe','Salt', 0.2, 'kg'),
  ('Gouda recipe','Rennet', 5, 'g'),
  ('Gouda recipe','Starter culture', 2, 'g'),
  ('Brie recipe','Milk', 10, 'L'),
  ('Brie recipe','Salt', 0.15, 'kg'),
  ('Brie recipe','Rennet', 4, 'g'),
  ('Brie recipe','Starter culture', 2, 'g')
) AS x(rname, rmname, qty, unit)
JOIN recipe r ON r.name = x.rname
JOIN raw_material rm ON rm.name = x.rmname
ON CONFLICT DO NOTHING;

INSERT INTO cheese_product(name, cheese_type, aging_days, base_price, recipe_id, is_active)
VALUES
  ('Gouda', 'Hard', 60, 12.50, (SELECT id FROM recipe WHERE name='Gouda recipe'), true),
  ('Brie',  'Soft', 21, 15.00, (SELECT id FROM recipe WHERE name='Brie recipe'),  true),
  ('Cheddar', 'Hard', 90, 14.00, NULL, true),
  ('Camembert', 'Soft', 21, 16.00, NULL, true)
ON CONFLICT (name) DO NOTHING;

INSERT INTO customer(full_name, phone, email, address)
VALUES
  ('Petro Customer', '380444444444', 'c1@cheese.local', 'Kyiv'),
  ('Iryna Customer', '380555555555', 'c2@cheese.local', 'Lviv'),
  ('Mykola Customer','380666666666', 'c3@cheese.local', 'Odesa')
ON CONFLICT (email) DO NOTHING;

SELECT public.create_batch(
  (SELECT id FROM cheese_product WHERE name='Gouda'),
  'GOUDA-BATCH-001',
  current_date - 5,
  120
);

SELECT public.record_quality_test(
  (SELECT id FROM batch WHERE code='GOUDA-BATCH-001'),
  (SELECT id FROM employee WHERE email='insp@cheese.local'),
  5.2, 42.0, 'OK', 'PASS'
);

SELECT public.create_order(
  (SELECT id FROM customer WHERE email='c1@cheese.local'),
  'PAID',
  'first order',
  jsonb_build_array(
    jsonb_build_object('product_id', (SELECT id FROM cheese_product WHERE name='Gouda'), 'qty', 2),
    jsonb_build_object('product_id', (SELECT id FROM cheese_product WHERE name='Brie'),  'qty', 1)
  )
);
