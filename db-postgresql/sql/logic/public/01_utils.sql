-- check email format
CREATE OR REPLACE FUNCTION public.check_email(email TEXT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
END;
$$ LANGUAGE plpgsql;

-- check number of digits in telephone number
CREATE OR REPLACE FUNCTION public.check_tel(tel_number TEXT) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (LENGTH(REGEXP_REPLACE(tel_number, '[^0-9]', '', 'g')) >= 10);
END;
$$ LANGUAGE plpgsql;

-- проверка пароля (как в примере "такси": минимум 8 символов, минимум 1 строчная, 1 заглавная, 1 цифра)
CREATE OR REPLACE FUNCTION public.check_password(password TEXT) RETURNS BOOLEAN AS $$
BEGIN
    -- PostgreSQL regex = POSIX (без lookahead и без \d), поэтому делаем проверку простыми условиями.
    IF password IS NULL OR length(password) < 8 THEN
        RETURN FALSE;
    END IF;

    IF password !~ '[a-z]' THEN
        RETURN FALSE;
    END IF;
    IF password !~ '[A-Z]' THEN
        RETURN FALSE;
    END IF;
    IF password !~ '[0-9]' THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- update changed_at column trigger function
CREATE OR REPLACE FUNCTION public.update_changed_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.changed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;