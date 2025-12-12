-- 1) best_before = prod_date + aging_days (если не задан)
CREATE OR REPLACE FUNCTION public.tg_set_batch_best_before()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE v_aging_days int;
BEGIN
  SELECT aging_days INTO v_aging_days
  FROM cheese_product
  WHERE id = NEW.product_id;

  IF v_aging_days IS NULL THEN
    RAISE EXCEPTION 'aging_days is null for product_id=%', NEW.product_id;
  END IF;

  IF NEW.best_before IS NULL THEN
    NEW.best_before := NEW.prod_date + v_aging_days;
  END IF;

  IF NEW.best_before < NEW.prod_date THEN
    RAISE EXCEPTION 'best_before cannot be earlier than prod_date';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS set_batch_best_before ON batch;
CREATE TRIGGER set_batch_best_before
BEFORE INSERT OR UPDATE OF product_id, prod_date, best_before
ON batch
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_batch_best_before();


-- 2) unit_price snapshot + проверки
CREATE OR REPLACE FUNCTION public.tg_set_order_item_unit_price()
RETURNS trigger
LANGUAGE plpgsql
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


-- 3) после PASS/FAIL обновляем batch.status
CREATE OR REPLACE FUNCTION public.tg_update_batch_status_on_quality()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'FAIL' THEN
    UPDATE batch SET status = 'REJECTED' WHERE id = NEW.batch_id;
  ELSIF NEW.status = 'PASS' THEN
    UPDATE batch SET status = 'RELEASED' WHERE id = NEW.batch_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS update_batch_status_on_quality ON quality_test;
CREATE TRIGGER update_batch_status_on_quality
AFTER INSERT OR UPDATE OF status
ON quality_test
FOR EACH ROW
EXECUTE FUNCTION public.tg_update_batch_status_on_quality();
