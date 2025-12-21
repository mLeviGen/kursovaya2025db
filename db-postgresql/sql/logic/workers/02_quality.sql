-- Контроль качества: фиксация результатов и просмотр логов

CREATE OR REPLACE FUNCTION workers.record_quality_test(
    p_batch_code VARCHAR,
    p_result public.test_result,
    p_ph NUMERIC DEFAULT NULL,
    p_moisture_pct NUMERIC DEFAULT NULL,
    p_comments TEXT DEFAULT NULL
) RETURNS BIGINT
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
DECLARE
    v_inspector_id BIGINT;
    v_role public.user_role_type;
    v_batch_id BIGINT;
    v_test_id BIGINT;
BEGIN
    v_inspector_id := public.get_my_id();
    SELECT role INTO v_role FROM private.users WHERE id = v_inspector_id;

    IF v_role NOT IN ('inspector', 'admin') THEN
        RAISE EXCEPTION 'Access denied: only inspectors can record tests';
    END IF;

    SELECT id INTO v_batch_id FROM private.batch WHERE code = p_batch_code;
    IF v_batch_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found: %', p_batch_code;
    END IF;

    -- Для наглядности переводим партию в статус "testing" перед записью теста.
    UPDATE private.batch
    SET status = 'testing'
    WHERE id = v_batch_id AND status = 'aging';

    INSERT INTO private.quality_test (
        batch_id,
        inspector_id,
        ph,
        moisture_pct,
        result,
        comments
    ) VALUES (
        v_batch_id,
        v_inspector_id,
        p_ph,
        p_moisture_pct,
        p_result,
        p_comments
    )
    RETURNING id INTO v_test_id;

    RETURN v_test_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION workers.get_quality_tests(
    p_batch_code VARCHAR
) RETURNS TABLE(
    test_id BIGINT,
    test_date TIMESTAMP,
    batch_code VARCHAR,
    product_name VARCHAR,
    inspector_name TEXT,
    result public.test_result,
    ph NUMERIC,
    moisture_pct NUMERIC,
    comments TEXT
)
SECURITY DEFINER
SET search_path = private, public, workers
AS $$
BEGIN
    RETURN QUERY
    SELECT
        qt.id,
        qt.test_date,
        b.code,
        p.name,
        COALESCE(u.first_name || ' ' || u.last_name, NULL),
        qt.result,
        qt.ph,
        qt.moisture_pct,
        qt.comments
    FROM private.quality_test qt
    JOIN private.batch b ON b.id = qt.batch_id
    JOIN private.product p ON p.id = b.product_id
    LEFT JOIN private.users u ON u.id = qt.inspector_id
    WHERE b.code = p_batch_code
    ORDER BY qt.test_date DESC;
END;
$$ LANGUAGE plpgsql;