-- Публичные представления для чтения (без прямого доступа к private.*)

-- Каталог продукции (для гостя/клиента/сотрудника)
CREATE OR REPLACE VIEW public.products_view AS
SELECT
    p.id,
    p.name,
    p.category::TEXT AS cheese_type,
    p.aging_days,
    p.base_price,
    p.is_active,
    r.name AS recipe_name
FROM private.product p
LEFT JOIN private.recipe r ON r.id = p.recipe_id;

GRANT SELECT ON public.products_view TO "guest", "client", "employee", "admin";


-- Партии производства (видят сотрудники)
CREATE OR REPLACE VIEW public.batches_view AS
SELECT
    b.id,
    b.code,
    p.name AS product_name,
    b.status,
    b.prod_date,
    b.best_before,
    b.qty_kg,
    b.created_at,
    b.changed_at
FROM private.batch b
JOIN private.product p ON p.id = b.product_id;

GRANT SELECT ON public.batches_view TO "employee", "admin";


-- Партии для публичного каталога: только выпущенные в продажу (released)
CREATE OR REPLACE VIEW public.batches_public_view AS
SELECT
    b.id,
    b.code,
    p.name AS product_name,
    b.status,
    b.prod_date,
    b.best_before,
    b.qty_kg
FROM private.batch b
JOIN private.product p ON p.id = b.product_id
WHERE b.status = 'released'
ORDER BY b.prod_date DESC, b.id DESC;

GRANT SELECT ON public.batches_public_view TO "guest", "client", "employee", "admin";


-- Заказы (обобщённый вид для сотрудников/админов)
CREATE OR REPLACE VIEW public.orders_view AS
SELECT
    o.id,
    u.login AS client_login,
    o.status,
    o.total_price,
    o.comments,
    o.created_at,
    o.changed_at,
    COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'product_id', p.id,
                'product', p.name,
                'qty', oi.qty,
                'unit_price', oi.unit_price
            ) ORDER BY p.name
        ) FILTER (WHERE oi.order_id IS NOT NULL),
        '[]'::jsonb
    ) AS items
FROM private.orders o
JOIN private.users u ON u.id = o.client_id
LEFT JOIN private.order_item oi ON oi.order_id = o.id
LEFT JOIN private.product p ON p.id = oi.product_id
GROUP BY o.id, u.login;

GRANT SELECT ON public.orders_view TO "employee", "admin";


-- Условия поставок (видят сотрудники)
CREATE OR REPLACE VIEW public.supplies_view AS
SELECT
    s.name AS supplier_name,
    r.name AS raw_material_name,
    r.unit,
    sp.cost_numeric,
    sp.lead_time_days
FROM private.supply sp
JOIN private.supplier s ON s.id = sp.supplier_id
JOIN private.raw_material r ON r.id = sp.raw_material_id;

GRANT SELECT ON public.supplies_view TO "employee", "admin";
