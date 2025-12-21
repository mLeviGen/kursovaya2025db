CREATE OR REPLACE PROCEDURE admin.create_psql_user(
    p_login VARCHAR,
    p_password VARCHAR,
    p_user_role public.user_role_type
) SECURITY DEFINER AS $$
DECLARE
    v_group_role VARCHAR;
BEGIN
    IF p_user_role = 'client' THEN
        v_group_role := 'client';
    ELSIF p_user_role = 'admin' THEN
        v_group_role := 'admin';
    ELSIF p_user_role IN ('technologist', 'inspector', 'manager') THEN
        v_group_role := 'employee'; 
    ELSE
        RAISE EXCEPTION 'Unknown role: %', p_user_role;
    END IF;

    EXECUTE FORMAT('CREATE USER %I WITH PASSWORD %L', p_login, p_password);
    EXECUTE FORMAT('GRANT %I TO %I', v_group_role, p_login);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE admin.register_user(
    p_login VARCHAR,
    p_password VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_role public.user_role_type
) SECURITY DEFINER AS $$
BEGIN
    INSERT INTO private.users (login, password_hash, email, phone, first_name, last_name, role)
    VALUES (p_login, p_password, p_email, p_phone, p_first_name, p_last_name, p_role);
    
    CALL admin.create_psql_user(p_login, p_password, p_role);
END;
$$ LANGUAGE plpgsql;