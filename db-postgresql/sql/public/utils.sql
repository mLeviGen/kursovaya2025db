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

-- update changed_at column trigger function
CREATE OR REPLACE FUNCTION public.update_changed_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.changed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;