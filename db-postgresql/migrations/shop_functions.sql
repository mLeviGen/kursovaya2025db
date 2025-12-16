-- Login (backend выдаёт JWT, но проверку делаем в БД)
CREATE OR REPLACE FUNCTION public.auth_login(
  p_username text,
  p_password text
) RETURNS TABLE(user_id int, user_type varchar, customer_id int, employee_id int)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.user_type, u.customer_id, u.employee_id
  FROM auth_user u
  WHERE u.username = p_username
    AND u.is_active
    AND u.password_hash = crypt(p_password, u.password_hash);

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid credentials';
  END IF;
END $$;

-- Заказ от лица клиента (без серверной корзины)
CREATE OR REPLACE FUNCTION public.place_order(
  p_user_id int,
  p_channel varchar,
  p_comments text,
  p_items jsonb
) RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_customer_id int;
  v_order_id int;
BEGIN
  IF p_channel NOT IN ('B2C','B2B') THEN
    RAISE EXCEPTION 'Invalid channel';
  END IF;

  SELECT customer_id INTO v_customer_id
  FROM auth_user
  WHERE id = p_user_id AND user_type = 'CUSTOMER' AND is_active;

  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'User is not a customer or inactive';
  END IF;

  -- твоя существующая функция:
  v_order_id := public.create_order(v_customer_id, 'NEW', p_comments, p_items);

  UPDATE customer_order
  SET channel = p_channel,
      created_by_user_id = p_user_id,
      updated_at = now()
  WHERE id = v_order_id;

  RETURN v_order_id;
END $$;
