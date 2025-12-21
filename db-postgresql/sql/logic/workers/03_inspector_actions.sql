-- Служебные функции для сотрудников (просмотр партий, заказов, ручные действия)

CREATE OR REPLACE FUNCTION workers.get_batches(
    p_status public.batch_status DEFAULT NULL
) RETURNS TABLE(
    batch_id BIGINT,
    code VARCHAR,
    product_name VARCHAR,
    status public.batch_status,
    prod_date DATE,
    best_before DATE,
    qty_kg NUMERIC,
    created_at TIMESTAMP,
    changed_at TIMESTAMP
)
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'inspector', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        b.id,
        b.code,
        p.name,
        b.status,
        b.prod_date,
        b.best_before,
        b.qty_kg,
        b.created_at,
        b.changed_at
    FROM private.batch b
    JOIN private.product p ON p.id = b.product_id
    WHERE (p_status IS NULL OR b.status = p_status)
    ORDER BY b.prod_date DESC, b.id DESC;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.set_batch_status(
    p_batch_code VARCHAR,
    p_status public.batch_status
) RETURNS VOID
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_batch_id BIGINT;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    -- ручные правки — только manager/admin
    IF v_role NOT IN ('manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied: only managers can change batch status manually';
    END IF;

    SELECT id INTO v_batch_id FROM private.batch WHERE code = p_batch_code;
    IF v_batch_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found: %', p_batch_code;
    END IF;

    UPDATE private.batch
    SET status = p_status
    WHERE id = v_batch_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.set_order_status(
    p_order_id BIGINT,
    p_status public.order_status
) RETURNS VOID
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_current public.order_status;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied: only managers can update orders';
    END IF;

    SELECT status INTO v_current FROM private.orders WHERE id = p_order_id;
    IF v_current IS NULL THEN
        RAISE EXCEPTION 'Order not found: %', p_order_id;
    END IF;

    -- Простая матрица переходов, чтобы не было "телепорта" статусов.
    IF v_current = 'cancelled' THEN
        RAISE EXCEPTION 'Cannot change cancelled order';
    END IF;

    IF v_current = 'completed' AND p_status <> 'completed' THEN
        RAISE EXCEPTION 'Cannot revert completed order';
    END IF;

    IF v_current = 'new' AND p_status NOT IN ('paid', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid transition % -> %', v_current, p_status;
    END IF;

    IF v_current = 'paid' AND p_status NOT IN ('shipped', 'cancelled') THEN
        RAISE EXCEPTION 'Invalid transition % -> %', v_current, p_status;
    END IF;

    IF v_current = 'shipped' AND p_status NOT IN ('completed') THEN
        RAISE EXCEPTION 'Invalid transition % -> %', v_current, p_status;
    END IF;

    UPDATE private.orders
    SET status = p_status
    WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.get_orders(
    p_status public.order_status DEFAULT NULL
) RETURNS TABLE(
    order_id BIGINT,
    client_login VARCHAR,
    status public.order_status,
    total_price NUMERIC,
    created_at TIMESTAMP,
    items JSONB
)
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        o.id,
        u.login,
        o.status,
        o.total_price,
        o.created_at,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'product', p.name,
                    'qty', oi.qty,
                    'unit_price', oi.unit_price
                ) ORDER BY p.name
            ) FILTER (WHERE oi.order_id IS NOT NULL),
            '[]'::jsonb
        )
    FROM private.orders o
    JOIN private.users u ON u.id = o.client_id
    LEFT JOIN private.order_item oi ON oi.order_id = o.id
    LEFT JOIN private.product p ON p.id = oi.product_id
    WHERE (p_status IS NULL OR o.status = p_status)
    GROUP BY o.id, u.login
    ORDER BY o.created_at DESC, o.id DESC;
END;
$$ LANGUAGE plpgsql;