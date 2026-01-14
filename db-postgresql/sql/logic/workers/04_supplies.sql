-- Снабжение: поставщики, сырьё и условия поставки

-- ВАЖНО (вариант B):
-- * manager может менять только cost/lead_time по supply_id (без изменения supplier/raw_material/unit)
-- * создание/правка связок supplier<->raw_material и unit разрешены только technologist/admin


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

    IF v_role NOT IN ('technologist', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO private.supplier(name, phone, email, address, rating)
    VALUES (p_name, p_phone, p_email, p_address, p_rating)
    ON CONFLICT (name) DO UPDATE SET
        phone = EXCLUDED.phone,
        email = EXCLUDED.email,
        address = EXCLUDED.address,
        rating = EXCLUDED.rating
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
    v_existing_unit VARCHAR;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    INSERT INTO private.raw_material(name, unit, shelf_life_days, allergen_flag)
    VALUES (p_name, p_unit, p_shelf_life_days, COALESCE(p_allergen_flag, FALSE))
    ON CONFLICT (name) DO NOTHING;

    SELECT id, unit INTO v_id, v_existing_unit
    FROM private.raw_material
    WHERE name = p_name;

    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Raw material not found and cannot be created: %', p_name;
    END IF;

    IF v_existing_unit <> p_unit THEN
        RAISE EXCEPTION 'Unit mismatch for raw material "%": existing=%, provided=%', p_name, v_existing_unit, p_unit;
    END IF;

    -- Обновляем дополнительные поля только если они переданы
    UPDATE private.raw_material
    SET
        shelf_life_days = COALESCE(p_shelf_life_days, shelf_life_days),
        allergen_flag = COALESCE(p_allergen_flag, allergen_flag)
    WHERE id = v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.upsert_supply(
    p_supplier_name VARCHAR,
    p_raw_material_name VARCHAR,
    p_unit VARCHAR,
    p_cost_numeric NUMERIC,
    p_lead_time_days INT DEFAULT NULL
) RETURNS BIGINT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
    v_supplier_id INT;
    v_raw_id INT;
    v_supply_id BIGINT;
    v_existing_unit VARCHAR;
    v_supplier_name VARCHAR;
    v_raw_name VARCHAR;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    v_supplier_name := TRIM(BOTH FROM p_supplier_name);
    v_raw_name := TRIM(BOTH FROM p_raw_material_name);

    -- supplier: create if missing
    INSERT INTO private.supplier(name)
    VALUES (v_supplier_name)
    ON CONFLICT (name) DO NOTHING;

    SELECT id INTO v_supplier_id FROM private.supplier WHERE name = v_supplier_name;
    IF v_supplier_id IS NULL THEN
        RAISE EXCEPTION 'Supplier not found and cannot be created: %', v_supplier_name;
    END IF;

    -- raw material: create if missing
    INSERT INTO private.raw_material(name, unit)
    VALUES (v_raw_name, p_unit)
    ON CONFLICT (name) DO NOTHING;

    SELECT id, unit INTO v_raw_id, v_existing_unit
    FROM private.raw_material
    WHERE name = v_raw_name;

    IF v_raw_id IS NULL THEN
        RAISE EXCEPTION 'Raw material not found and cannot be created: %', v_raw_name;
    END IF;

    IF v_existing_unit <> p_unit THEN
        RAISE EXCEPTION 'Unit mismatch for raw material "%": existing=%, provided=%', v_raw_name, v_existing_unit, p_unit;
    END IF;

    INSERT INTO private.supply(supplier_id, raw_material_id, cost_numeric, lead_time_days)
    VALUES (v_supplier_id, v_raw_id, p_cost_numeric, p_lead_time_days)
    ON CONFLICT (supplier_id, raw_material_id)
    DO UPDATE SET
        cost_numeric = EXCLUDED.cost_numeric,
        lead_time_days = EXCLUDED.lead_time_days
    RETURNING id INTO v_supply_id;

    RETURN v_supply_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.update_supply_terms(
    p_supply_id BIGINT,
    p_cost_numeric NUMERIC DEFAULT NULL,
    p_lead_time_days INT DEFAULT NULL
) RETURNS BIGINT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_user_id BIGINT;
    v_role public.user_role_type;
BEGIN
    v_user_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_user_id;

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    IF p_cost_numeric IS NULL AND p_lead_time_days IS NULL THEN
        RAISE EXCEPTION 'Nothing to update';
    END IF;

    UPDATE private.supply
    SET
        cost_numeric = COALESCE(p_cost_numeric, cost_numeric),
        lead_time_days = COALESCE(p_lead_time_days, lead_time_days)
    WHERE id = p_supply_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Supply not found: %', p_supply_id;
    END IF;

    RETURN p_supply_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.get_supplies()
RETURNS TABLE(
    supply_id BIGINT,
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

    IF v_role NOT IN ('technologist', 'manager', 'admin') THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT
        sp.id,
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
