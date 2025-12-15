-- Создание партии (best_before поставит триггер)
CREATE OR REPLACE FUNCTION public.create_batch(
  p_product_id int,
  p_code varchar,
  p_prod_date date,
  p_qty_kg real
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_batch_id int;
BEGIN
  INSERT INTO batch(product_id, code, prod_date, qty_kg, status, best_before)
  VALUES (p_product_id, p_code, p_prod_date, p_qty_kg, 'PLANNED', NULL)
  RETURNING id INTO v_batch_id;

  RETURN v_batch_id;
END $$;

-- Запись теста качества (статус партии обновит триггер)
CREATE OR REPLACE FUNCTION public.record_quality_test(
  p_batch_id int,
  p_inspector_id int,
  p_ph real,
  p_moisture_pct real,
  p_micro_bio varchar,
  p_status varchar
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_test_id int;
BEGIN
  INSERT INTO quality_test(batch_id, inspector_id, ph, moisture_pct, micro_bio, status)
  VALUES (p_batch_id, p_inspector_id, p_ph, p_moisture_pct, p_micro_bio, p_status)
  RETURNING id INTO v_test_id;

  RETURN v_test_id;
END $$;

-- Создание заказа одним вызовом (items: [{"product_id":1,"qty":2}, ...])
CREATE OR REPLACE FUNCTION public.create_order(
  p_customer_id int,
  p_status varchar,
  p_comments text,
  p_items jsonb
)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_order_id int;
DECLARE v_item jsonb;
DECLARE v_product_id int;
DECLARE v_qty real;
BEGIN
  IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION 'items must be a JSON array';
  END IF;

  INSERT INTO customer_order(customer_id, order_date, status, comments)
  VALUES (p_customer_id, current_date, COALESCE(p_status,'NEW'), p_comments)
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::int;
    v_qty := (v_item->>'qty')::real;

    INSERT INTO order_item(order_id, product_id, qty, unit_price)
    VALUES (v_order_id, v_product_id, v_qty, NULL); -- цену/валидации сделает триггер
  END LOOP;

  RETURN v_order_id;
END $$;

-- Права: приложению разрешаем только EXECUTE на функции
REVOKE ALL ON FUNCTION public.create_batch(int, varchar, date, real) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.record_quality_test(int, int, real, real, varchar, varchar) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_order(int, varchar, text, jsonb) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.create_batch(int, varchar, date, real) TO cheese_app;
GRANT EXECUTE ON FUNCTION public.record_quality_test(int, int, real, real, varchar, varchar) TO cheese_app;
GRANT EXECUTE ON FUNCTION public.create_order(int, varchar, text, jsonb) TO cheese_app;

-- Процедура: отмена заказа (формально закрывает требование PROCEDURE)
-- Логика: нельзя отменить уже SHIPPED, можно отменять NEW/PAID.
CREATE OR REPLACE PROCEDURE public.cancel_order(p_order_id int, p_reason text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE v_status varchar(15);
BEGIN
  SELECT status INTO v_status
  FROM customer_order
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'order not found: %', p_order_id;
  END IF;

  IF v_status = 'SHIPPED' THEN
    RAISE EXCEPTION 'cannot cancel shipped order: %', p_order_id;
  END IF;

  IF v_status = 'CANCELLED' THEN
    RETURN;
  END IF;

  UPDATE customer_order
  SET status = 'CANCELLED',
      comments = trim(both from COALESCE(comments, '') || E'\n' || 'CANCEL: ' || COALESCE(p_reason,''))
  WHERE id = p_order_id;
END $$;

REVOKE ALL ON PROCEDURE public.cancel_order(int, text) FROM PUBLIC;
GRANT EXECUTE ON PROCEDURE public.cancel_order(int, text) TO cheese_app;
