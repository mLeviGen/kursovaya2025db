CREATE OR REPLACE VIEW admin.users_view AS
SELECT
    u.id,
    u.login,
    u.email,
    u.phone,
    u.first_name,
    u.last_name,
    u.role,
    u.hire_date,
    u.created_at,
    u.changed_at
FROM private.users AS u;

CREATE OR REPLACE VIEW admin.clients_stats_view AS
SELECT
    u.id AS client_id,
    u.login,
    u.first_name,
    u.last_name,
    u.email,
    COUNT(o.id) AS total_orders,
    COUNT(o.id) FILTER (WHERE o.status = 'completed') AS completed_orders,
    COUNT(o.id) FILTER (WHERE o.status = 'cancelled') AS cancelled_orders,
    COALESCE(SUM(o.total_price), 0) AS total_spent_money,
    MAX(o.created_at) AS last_order_date
FROM private.users u
LEFT JOIN private.orders o ON o.client_id = u.id
WHERE u.role = 'client'
GROUP BY u.id, u.login, u.first_name, u.last_name, u.email;

CREATE OR REPLACE VIEW admin.product_sales_view AS
SELECT
    p.id AS product_id,
    p.name AS product_name,
    p.category,
    p.is_active,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    COALESCE(SUM(oi.qty), 0) AS units_sold,
    COALESCE(SUM(oi.qty * oi.unit_price), 0) AS revenue
FROM private.product p
LEFT JOIN private.order_item oi ON oi.product_id = p.id
LEFT JOIN private.orders o ON o.id = oi.order_id AND o.status = 'completed' 
GROUP BY p.id, p.name, p.category, p.is_active
ORDER BY revenue DESC;

CREATE OR REPLACE VIEW admin.production_stats_view AS
SELECT
    p.name AS product_name,
    COUNT(b.id) AS total_batches_produced,
    SUM(b.qty_kg) AS total_kg_produced,
    COUNT(b.id) FILTER (WHERE b.status = 'released') AS released_batches,
    COUNT(b.id) FILTER (WHERE b.status = 'rejected') AS rejected_batches,
    ROUND(
        (COUNT(b.id) FILTER (WHERE b.status = 'rejected')::NUMERIC / NULLIF(COUNT(b.id), 0) * 100), 
        2
    ) AS rejection_rate_pct
FROM private.product p
LEFT JOIN private.batch b ON b.product_id = p.id
GROUP BY p.name;

CREATE OR REPLACE VIEW admin.quality_log_view AS
SELECT
    qt.id AS test_id,
    qt.test_date,
    b.code AS batch_code,
    p.name AS product_name,
    (u.first_name || ' ' || u.last_name) AS inspector_name,
    qt.result AS test_result, 
    qt.ph,
    qt.moisture_pct,
    qt.comments
FROM private.quality_test qt
JOIN private.batch b ON b.id = qt.batch_id
JOIN private.product p ON p.id = b.product_id
LEFT JOIN private.users u ON u.id = qt.inspector_id;

GRANT SELECT ON ALL TABLES IN SCHEMA admin TO "admin";
GRANT SELECT ON admin.product_sales_view TO "employee";
GRANT SELECT ON admin.production_stats_view TO "employee";