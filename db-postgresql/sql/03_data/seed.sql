CALL admin.register_user(
    'tech_ivan', 'pass123', 'tech@cheese.local', '+380000000001', 
    'Ivan', 'Petrenko', 'technologist'
);

CALL admin.register_user(
    'insp_oleh', 'pass123', 'insp@cheese.local', '+380000000002', 
    'Oleh', 'Koval', 'inspector'
);

CALL admin.register_user(
    'mgr_anna', 'pass123', 'mgr@cheese.local', '+380000000003', 
    'Anna', 'Shevchenko', 'manager'
);

CALL admin.register_user(
    'client_petro', 'clientpass', 'c1@cheese.local', '+380444444444', 
    'Petro', 'Bumaga', 'client'
);

CALL admin.register_user(
    'client_iryna', 'clientpass', 'c2@cheese.local', '+380555555555', 
    'Iryna', 'Kiyashko', 'client'
);


INSERT INTO private.supplier (name, phone, email, address, rating) VALUES
('MilkFarm LLC', '+380111111111', 'milk@sup.local', 'Kyiv Region', 5),
('Salt&Co',      '+380222222222', 'salt@sup.local', 'Lviv Region', 4),
('CultureLab',   '+380333333333', 'cult@sup.local', 'Odesa', 5);

INSERT INTO private.raw_material (name, unit, shelf_life_days, allergen_flag) VALUES
('Milk', 'L', 7, true),
('Salt', 'kg', 3650, false),
('Rennet', 'g', 365, false),
('Starter culture', 'g', 365, false);

INSERT INTO private.supply (supplier_id, raw_material_id, cost_numeric, lead_time_days)
SELECT s.id, r.id, 0.80, 1 FROM private.supplier s, private.raw_material r WHERE s.name='MilkFarm LLC' AND r.name='Milk';

INSERT INTO private.supply (supplier_id, raw_material_id, cost_numeric, lead_time_days)
SELECT s.id, r.id, 1.20, 2 FROM private.supplier s, private.raw_material r WHERE s.name='Salt&Co' AND r.name='Salt';


DO $$
DECLARE
    v_tech_id BIGINT;
    v_recipe_id INT;
BEGIN
    SELECT id INTO v_tech_id FROM private.users WHERE login = 'tech_ivan';

    INSERT INTO private.recipe (name, description, yield_pct, author_id)
    VALUES ('Gouda Classic', 'Traditional Dutch cheese recipe', 90, v_tech_id)
    RETURNING id INTO v_recipe_id;

    INSERT INTO private.recipe_ingredient (recipe_id, raw_material_id, qty, unit)
    SELECT v_recipe_id, id, 10, 'L' FROM private.raw_material WHERE name = 'Milk';
    
    INSERT INTO private.recipe_ingredient (recipe_id, raw_material_id, qty, unit)
    SELECT v_recipe_id, id, 0.2, 'kg' FROM private.raw_material WHERE name = 'Salt';

    INSERT INTO private.product (name, category, aging_days, base_price, recipe_id, is_active)
    VALUES ('Gouda', 'hard', 60, 12.50, v_recipe_id, true);
    
    INSERT INTO private.product (name, category, aging_days, base_price, recipe_id, is_active)
    VALUES ('Brie', 'soft', 21, 15.00, NULL, true);
END $$;


INSERT INTO private.batch (code, product_id, prod_date, qty_kg, status)
VALUES 
('BATCH-GOUDA-001', (SELECT id FROM private.product WHERE name='Gouda'), CURRENT_DATE - 10, 500.00, 'aging'),
('BATCH-BRIE-001',  (SELECT id FROM private.product WHERE name='Brie'),  CURRENT_DATE - 5,  200.00, 'aging');

INSERT INTO private.quality_test (batch_id, inspector_id, ph, moisture_pct, result, comments)
VALUES 
(
    (SELECT id FROM private.batch WHERE code='BATCH-GOUDA-001'),
    (SELECT id FROM private.users WHERE login='insp_oleh'),
    5.2, 
    41.5, 
    'pass', 
    'Perfect batch'
);

DO $$
DECLARE
    v_client_id BIGINT;
    v_order_id BIGINT;
    v_prod1 INT;
    v_prod2 INT;
BEGIN
    SELECT id INTO v_client_id FROM private.users WHERE login = 'client_petro';
    SELECT id INTO v_prod1 FROM private.product WHERE name = 'Gouda';
    SELECT id INTO v_prod2 FROM private.product WHERE name = 'Brie';

    INSERT INTO private.orders (client_id, status, comments)
    VALUES (v_client_id, 'new', 'Please deliver fast')
    RETURNING id INTO v_order_id;

    INSERT INTO private.order_item (order_id, product_id, qty) VALUES (v_order_id, v_prod1, 5); -- 5 * 12.50
    INSERT INTO private.order_item (order_id, product_id, qty) VALUES (v_order_id, v_prod2, 2); -- 2 * 15.00
END $$;