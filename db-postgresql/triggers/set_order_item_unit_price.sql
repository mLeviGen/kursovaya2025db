CREATE OR REPLACE FUNCTION public.tg_set_order_item_unit_price()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE v_price numeric(10,2);
DECLARE v_active boolean;
BEGIN
  SELECT base_price, is_active INTO v_price, v_active
  FROM cheese_product
  WHERE id = NEW.product_id;

  IF v_price IS NULL THEN
    RAISE EXCEPTION 'product not found: %', NEW.product_id;
  END IF;

  IF v_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'product is not active: %', NEW.product_id;
  END IF;

  IF NEW.qty IS NULL OR NEW.qty <= 0 THEN
    RAISE EXCEPTION 'qty must be > 0';
  END IF;

  IF NEW.unit_price IS NULL THEN
    NEW.unit_price := v_price;
  END IF;

  IF NEW.unit_price < 0 THEN
    RAISE EXCEPTION 'unit_price must be >= 0';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS set_order_item_unit_price ON order_item;

CREATE TRIGGER set_order_item_unit_price
BEFORE INSERT OR UPDATE OF product_id, qty, unit_price
ON order_item
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_order_item_unit_price();
