CREATE OR REPLACE FUNCTION public.tg_set_batch_best_before()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
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
