CREATE OR REPLACE FUNCTION public.tg_set_order_item_unit_price_shop()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_channel varchar(10);
  v_base numeric(10,2);
  v_price numeric(10,2);
BEGIN
  SELECT channel INTO v_channel FROM customer_order WHERE id = NEW.order_id;
  IF v_channel IS NULL THEN v_channel := 'B2C'; END IF;

  SELECT base_price INTO v_base FROM cheese_product WHERE id = NEW.product_id;

  IF v_channel = 'B2B' AND NEW.qty >= 10 THEN
    v_price := (v_base * 0.90);
  ELSE
    v_price := v_base;
  END IF;

  NEW.unit_price := v_price;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS set_order_item_unit_price ON order_item;
CREATE TRIGGER set_order_item_unit_price
BEFORE INSERT OR UPDATE OF qty, product_id, order_id ON order_item
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_order_item_unit_price_shop();
