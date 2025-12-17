-- Файл workers/quality.sql
CREATE OR REPLACE FUNCTION workers.record_quality_test(
    p_batch_code VARCHAR,
    p_ph NUMERIC,
    p_status VARCHAR
) RETURNS VOID SECURITY DEFINER AS $$
DECLARE
    v_inspector_id BIGINT;
    v_user_role public.user_role_type;
BEGIN
    v_inspector_id := public.get_my_id();
    
    -- Проверка, что это именно инспектор (бизнес-логика)
    SELECT role INTO v_user_role FROM private.users WHERE id = v_inspector_id;
    IF v_user_role != 'inspector' THEN
        RAISE EXCEPTION 'Only inspectors can perform tests';
    END IF;

    INSERT INTO private.quality_test (batch_id, inspector_id, ph, status)
    VALUES ((SELECT id FROM private.batch WHERE code = p_batch_code), v_inspector_id, p_ph, p_status);
END;
$$ LANGUAGE plpgsql;