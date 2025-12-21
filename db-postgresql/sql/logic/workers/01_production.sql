-- Производство: создание партии (batch)

CREATE OR REPLACE FUNCTION workers.create_batch(
    p_product_name VARCHAR,
    p_batch_code VARCHAR,
    p_qty_kg NUMERIC
) RETURNS BIGINT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_product_id INT;
    v_batch_id BIGINT;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied: only technologists/managers can create batches';
    END IF;

    SELECT id INTO v_product_id FROM private.product WHERE name = p_product_name;
    IF v_product_id IS NULL THEN
         RAISE EXCEPTION 'Product not found: %', p_product_name;
    END IF;

    INSERT INTO private.batch (product_id, code, prod_date, qty_kg, status)
    VALUES (v_product_id, p_batch_code, CURRENT_DATE, p_qty_kg, 'aging')
    RETURNING id INTO v_batch_id;

    RETURN v_batch_id;
END;
$$ LANGUAGE plpgsql;
