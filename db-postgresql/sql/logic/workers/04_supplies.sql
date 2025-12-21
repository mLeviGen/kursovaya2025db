-- Снабжение: поставщики, сырьё и условия поставки

CREATE OR REPLACE FUNCTION workers.create_supplier(
    p_name VARCHAR,
    p_phone VARCHAR DEFAULT NULL,
    p_email VARCHAR DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_rating INT DEFAULT NULL
) RETURNS INT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_id INT;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO private.supplier(name, phone, email, address, rating)
    VALUES (p_name, p_phone, p_email, p_address, p_rating)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.create_raw_material(
    p_name VARCHAR,
    p_unit VARCHAR,
    p_shelf_life_days INT DEFAULT NULL,
    p_allergen_flag BOOLEAN DEFAULT FALSE
) RETURNS INT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_id INT;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO private.raw_material(name, unit, shelf_life_days, allergen_flag)
    VALUES (p_name, p_unit, p_shelf_life_days, COALESCE(p_allergen_flag, FALSE))
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.upsert_supply(
    p_supplier_name VARCHAR,
    p_raw_material_name VARCHAR,
    p_cost_numeric NUMERIC,
    p_lead_time_days INT DEFAULT NULL
) RETURNS VOID
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_supplier_id INT;
    v_raw_id INT;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    SELECT id INTO v_supplier_id FROM private.supplier WHERE name = p_supplier_name;
    IF v_supplier_id IS NULL THEN
        RAISE EXCEPTION 'Supplier not found: %', p_supplier_name;
    END IF;

    SELECT id INTO v_raw_id FROM private.raw_material WHERE name = p_raw_material_name;
    IF v_raw_id IS NULL THEN
        RAISE EXCEPTION 'Raw material not found: %', p_raw_material_name;
    END IF;

    INSERT INTO private.supply(supplier_id, raw_material_id, cost_numeric, lead_time_days)
    VALUES (v_supplier_id, v_raw_id, p_cost_numeric, p_lead_time_days)
    ON CONFLICT (supplier_id, raw_material_id)
    DO UPDATE SET
        cost_numeric = EXCLUDED.cost_numeric,
        lead_time_days = EXCLUDED.lead_time_days;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.get_supplies()
RETURNS TABLE(
    supplier_name VARCHAR,
    raw_material_name VARCHAR,
    unit VARCHAR,
    cost_numeric NUMERIC,
    lead_time_days INT
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

    IF v_role NOT IN ('technologist', 'manager', 'admin', 'inspector') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        s.name,
        r.name,
        r.unit,
        sp.cost_numeric,
        sp.lead_time_days
    FROM private.supply sp
    JOIN private.supplier s ON s.id = sp.supplier_id
    JOIN private.raw_material r ON r.id = sp.raw_material_id
    ORDER BY s.name, r.name;
END;
$$ LANGUAGE plpgsql;
