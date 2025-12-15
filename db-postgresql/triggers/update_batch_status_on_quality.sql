CREATE OR REPLACE FUNCTION public.tg_update_batch_status_on_quality()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
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
