CREATE OR REPLACE FUNCTION authorized.make_order(
    p_items JSONB, 
    p_comments TEXT DEFAULT NULL
) RETURNS BIGINT
SECURITY DEFINER
SET search_path = private, public, authorized
AS $$
DECLARE
    v_client_id BIGINT;
    v_order_id BIGINT;
    v_item JSONB;
    v_product_name VARCHAR;
    v_qty INT;
    v_product_id INT;
BEGIN
    v_client_id := public.get_my_id();

    INSERT INTO private.orders (client_id, status, comments)
    VALUES (v_client_id, 'new', p_comments)
    RETURNING id INTO v_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_name := v_item->>'product';
        v_qty := (v_item->>'qty')::INT;

        SELECT id INTO v_product_id FROM private.product WHERE name = v_product_name;
        IF v_product_id IS NULL THEN
            RAISE EXCEPTION 'Product not found: %', v_product_name;
        END IF;

        INSERT INTO private.order_item (order_id, product_id, qty)
        VALUES (v_order_id, v_product_id, v_qty);
    END LOOP;

    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION authorized.cancel_my_order(
    p_order_id BIGINT
) RETURNS VOID
SECURITY DEFINER
SET search_path = private, public, authorized
AS $$
DECLARE
    v_client_id BIGINT;
    v_current_status public.order_status;
BEGIN
    v_client_id := public.get_my_id();

    SELECT status INTO v_current_status 
    FROM private.orders 
    WHERE id = p_order_id AND client_id = v_client_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Order not found or access denied';
    END IF;

    IF v_current_status IN ('shipped', 'completed') THEN
        RAISE EXCEPTION 'Cannot cancel order in status %', v_current_status;
    END IF;

    UPDATE private.orders 
    SET status = 'cancelled' 
    WHERE id = p_order_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION authorized.get_my_orders()
RETURNS TABLE (
    order_id BIGINT,
    status public.order_status,
    total_price NUMERIC,
    created_at TIMESTAMP,
    items JSONB
) SECURITY DEFINER
SET search_path = private, public, authorized
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id, 
        o.status, 
        o.total_price, 
        o.created_at,
        COALESCE(
            jsonb_agg(jsonb_build_object('product', p.name, 'qty', oi.qty, 'price', oi.unit_price))
            FILTER (WHERE oi.order_id IS NOT NULL),
            '[]'::jsonb
        )
    FROM private.orders o
    JOIN private.order_item oi ON oi.order_id = o.id
    JOIN private.product p ON p.id = oi.product_id
    WHERE o.client_id = public.get_my_id()
    GROUP BY o.id;
END;
$$ LANGUAGE plpgsql;