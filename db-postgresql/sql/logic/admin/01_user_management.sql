CREATE OR REPLACE PROCEDURE admin.create_psql_user(
    p_login VARCHAR,
    p_password VARCHAR,
    p_user_role public.user_role_type
) SECURITY DEFINER AS $$
DECLARE
    v_group_role VARCHAR;
    v_revoke_role VARCHAR;
    v_grantor_role VARCHAR;
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

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = p_login) THEN
        EXECUTE FORMAT('ALTER USER %I WITH PASSWORD %L', p_login, p_password);
    ELSE
        EXECUTE FORMAT('CREATE USER %I WITH PASSWORD %L', p_login, p_password);
    END IF;

FOR v_revoke_role, v_grantor_role IN
    SELECT r.rolname, g.rolname
    FROM pg_auth_members m
    JOIN pg_roles r ON r.oid = m.roleid
    JOIN pg_roles u ON u.oid = m.member
    JOIN pg_roles g ON g.oid = m.grantor
    WHERE u.rolname = p_login
      AND r.rolname IN ('admin', 'employee', 'client', 'guest')
LOOP
    EXECUTE format('REVOKE %I FROM %I GRANTED BY %I', v_revoke_role, p_login, v_grantor_role);
END LOOP;

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
    IF NOT public.check_password(p_password) THEN
        RAISE EXCEPTION 'Пароль слишком слабый: минимум 8 символов, 1 строчная, 1 заглавная, 1 цифра';
    END IF;

    -- Храним хэш, а не пароль. Сам пароль нужен только для создания PostgreSQL-пользователя.
    INSERT INTO private.users (login, password_hash, email, phone, first_name, last_name, role)
    VALUES (
        p_login,
        crypto.crypt(p_password, crypto.gen_salt('bf', 12)),
        p_email,
        p_phone,
        p_first_name,
        p_last_name,
        p_role
    );

    CALL admin.create_psql_user(p_login, p_password, p_role);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION admin.authenticate(
    p_login VARCHAR,
    p_password VARCHAR
) RETURNS TABLE(
    id BIGINT,
    role public.user_role_type
) SECURITY DEFINER
SET search_path = private, public, admin, crypto
AS $$
DECLARE
    v_ok BOOLEAN;
BEGIN
    SELECT (crypto.crypt(p_password, u.password_hash) = u.password_hash)
    INTO v_ok
    FROM private.users u
    WHERE u.login = p_login;

    IF v_ok IS NULL OR v_ok IS FALSE THEN
        RAISE EXCEPTION 'Неверный логин или пароль';
    END IF;

    RETURN QUERY
    SELECT u.id, u.role
    FROM private.users u
    WHERE u.login = p_login;
END;
$$ LANGUAGE plpgsql;