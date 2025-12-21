CREATE OR REPLACE PROCEDURE public.sign_up(
    p_login VARCHAR,
    p_password VARCHAR,
    p_email VARCHAR,
    p_phone VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR
) SECURITY DEFINER AS $$
BEGIN
    CALL admin.register_user(
        p_login, 
        p_password, 
        p_email, 
        p_phone, 
        p_first_name, 
        p_last_name, 
        'client'::public.user_role_type
    );
END;
$$ LANGUAGE plpgsql;

-- Проверка логина/пароля. Возвращает id пользователя и роль.
CREATE OR REPLACE FUNCTION public.authenticate(
    p_login VARCHAR,
    p_password VARCHAR
) RETURNS TABLE(
    id BIGINT,
    role public.user_role_type
) SECURITY DEFINER
SET search_path = private, public, admin, crypto
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM admin.authenticate(p_login, p_password);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.get_my_id() 
RETURNS BIGINT 
SECURITY DEFINER 
STABLE AS $$
DECLARE
    v_id BIGINT;
BEGIN
    SELECT id INTO v_id 
    FROM private.users 
    WHERE login = CURRENT_USER;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.me() 
RETURNS TABLE(
    id BIGINT, 
    login VARCHAR, 
    first_name VARCHAR, 
    last_name VARCHAR, 
    role public.user_role_type
) SECURITY DEFINER STABLE AS $$
BEGIN
    RETURN QUERY
    SELECT u.id, u.login, u.first_name, u.last_name, u.role
    FROM private.users u
    WHERE u.login = CURRENT_USER;
END;
$$ LANGUAGE plpgsql;