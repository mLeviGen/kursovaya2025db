-- 1. Получение ID текущего пользователя из сессии
CREATE OR REPLACE FUNCTION public.get_current_user_from_session() 
RETURNS BIGINT SECURITY DEFINER AS $$
DECLARE
    user_id BIGINT;
BEGIN
    -- SESSION_USER - это роль Postgres, под которой мы зашли (напр. 'client_petro')
    user_id := (SELECT id FROM private.users WHERE login = SESSION_USER);
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'User not found for login: %', SESSION_USER;
    END IF;
    RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Регистрация с хэшированием пароля
CREATE OR REPLACE FUNCTION public.register(
    p_login VARCHAR(32),
    p_password VARCHAR(32), -- Принимаем чистый пароль
    p_first_name VARCHAR(32),
    p_last_name VARCHAR(32),
    p_email VARCHAR(128),
    p_tel_number VARCHAR(32)
) RETURNS SETOF admin.users_view SECURITY DEFINER AS $$
DECLARE
    created_user_id BIGINT;
    hashed_password VARCHAR(512);
BEGIN
    -- Валидация пароля
    IF (NOT public.check_password(p_password)) THEN
        RAISE EXCEPTION 'Password too weak!';
    END IF;

    -- Хэшируем (Blowfish alg, salt 12)
    hashed_password := crypto.crypt(p_password, crypto.gen_salt('bf', 12));

    INSERT INTO private.users (login, password_hash, first_name, last_name, email, tel_number, role)
    VALUES (p_login, hashed_password, p_first_name, p_last_name, p_email, p_tel_number, 'client')
    RETURNING id INTO created_user_id;

    -- Создаем роль в Postgres (пароль для подключения такой же, как при регистрации)
    CALL admin.create_psql_user(p_login, p_password);
    CALL admin.set_psql_user_role(p_login, 'client');

    RETURN QUERY
        SELECT * FROM admin.users_view WHERE id = created_user_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Аутентификация (Проверка пароля)
CREATE OR REPLACE FUNCTION public.authenticate(
    p_login VARCHAR(32),
    p_password VARCHAR(32)
) RETURNS TABLE(id BIGINT, role public.user_role_type) SECURITY DEFINER AS $$
BEGIN
    -- Сравниваем введенный пароль с хэшем в базе
    RETURN QUERY
    SELECT u.id, u.role 
    FROM private.users u
    WHERE u.login = p_login 
    AND u.password_hash = crypto.crypt(p_password, u.password_hash);
END;
$$ LANGUAGE plpgsql;