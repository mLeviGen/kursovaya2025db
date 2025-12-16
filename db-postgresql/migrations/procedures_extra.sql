CREATE OR REPLACE FUNCTION public.calc_recipe_cost(p_recipe_id int)
RETURNS numeric(12,2)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_bad_units int;
  v_missing_prices int;
  v_cost numeric(12,2);
BEGIN
  SELECT COUNT(*) INTO v_bad_units
  FROM recipe_ingredient ri
  JOIN raw_material rm ON rm.id = ri.raw_material_id
  WHERE ri.recipe_id = p_recipe_id
    AND ri.unit <> rm.unit;

  IF v_bad_units > 0 THEN
    RAISE EXCEPTION 'Единицы измерения не совпадают в рецепте id=%', p_recipe_id;
  END IF;

  SELECT COUNT(*) INTO v_missing_prices
  FROM recipe_ingredient ri
  LEFT JOIN (
    SELECT raw_material_id
    FROM supply
    GROUP BY raw_material_id
  ) s ON s.raw_material_id = ri.raw_material_id
  WHERE ri.recipe_id = p_recipe_id
    AND s.raw_material_id IS NULL;

  IF v_missing_prices > 0 THEN
    RAISE EXCEPTION 'Нет цен поставки для части ингредиентов рецепта id=%', p_recipe_id;
  END IF;

  SELECT COALESCE(SUM(ri.qty * sc.min_cost), 0)::numeric(12,2)
  INTO v_cost
  FROM recipe_ingredient ri
  JOIN (
    SELECT raw_material_id, MIN(cost_numeric) AS min_cost
    FROM supply
    GROUP BY raw_material_id
  ) sc ON sc.raw_material_id = ri.raw_material_id
  WHERE ri.recipe_id = p_recipe_id;

  RETURN v_cost;
END $$;

CREATE OR REPLACE PROCEDURE public.pay_order(p_order_id int, p_payment_ref text DEFAULT NULL)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status varchar(15);
  v_items_count int;
  v_total numeric(12,2);
BEGIN
  SELECT status INTO v_status
  FROM customer_order
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Заказ id=% не найден', p_order_id;
  END IF;

  IF v_status <> 'NEW' THEN
    RAISE EXCEPTION 'Нельзя оплатить заказ id=% в статусе %', p_order_id, v_status;
  END IF;

  SELECT COUNT(*),
         COALESCE(SUM(qty * unit_price), 0)::numeric(12,2)
  INTO v_items_count, v_total
  FROM order_item
  WHERE order_id = p_order_id;

  IF v_items_count = 0 THEN
    RAISE EXCEPTION 'Нельзя оплатить пустой заказ id=%', p_order_id;
  END IF;

  IF v_total <= 0 THEN
    RAISE EXCEPTION 'Сумма заказа id=% должна быть > 0 (сейчас=%)', p_order_id, v_total;
  END IF;

  UPDATE customer_order
  SET status = 'PAID',
      total_amount = v_total,
      updated_at = now(),
      comments =
        CASE
          WHEN p_payment_ref IS NULL OR btrim(p_payment_ref) = '' THEN comments
          ELSE
            COALESCE(comments, '') ||
            CASE WHEN comments IS NULL OR comments = '' THEN '' ELSE E'\n' END ||
            'PAYMENT_REF: ' || p_payment_ref
        END
  WHERE id = p_order_id;
END $$;

CREATE OR REPLACE PROCEDURE public.ship_order(p_order_id int, p_tracking text DEFAULT NULL)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status varchar(15);
  v_customer_id int;
  v_addr text;
BEGIN
  SELECT status, customer_id INTO v_status, v_customer_id
  FROM customer_order
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Заказ id=% не найден', p_order_id;
  END IF;

  IF v_status <> 'PAID' THEN
    RAISE EXCEPTION 'Нельзя отгрузить заказ id=% в статусе % (нужен PAID)', p_order_id, v_status;
  END IF;

  SELECT address INTO v_addr
  FROM customer
  WHERE id = v_customer_id;

  IF v_addr IS NULL OR btrim(v_addr) = '' THEN
    RAISE EXCEPTION 'Нельзя отгрузить заказ id=%: у клиента нет адреса', p_order_id;
  END IF;

  UPDATE customer_order
  SET status = 'SHIPPED',
      updated_at = now(),
      comments =
        CASE
          WHEN p_tracking IS NULL OR btrim(p_tracking) = '' THEN comments
          ELSE
            COALESCE(comments, '') ||
            CASE WHEN comments IS NULL OR comments = '' THEN '' ELSE E'\n' END ||
            'TRACKING: ' || p_tracking
        END
  WHERE id = p_order_id;
END $$;

GRANT EXECUTE ON FUNCTION public.calc_recipe_cost(int) TO cheese_app;
GRANT EXECUTE ON PROCEDURE public.pay_order(int, text) TO cheese_app;
GRANT EXECUTE ON PROCEDURE public.ship_order(int, text) TO cheese_app;
