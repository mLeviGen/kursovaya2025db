CREATE OR REPLACE FUNCTION public.tg_check_inspector_role()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.inspector_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM employee e
    JOIN role r ON r.id = e.role_id
    WHERE e.id = NEW.inspector_id
      AND r.name = 'Inspector'
  ) THEN
    RAISE EXCEPTION 'inspector_id=% must reference employee with role=Inspector', NEW.inspector_id;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS check_inspector_role ON quality_test;

CREATE TRIGGER check_inspector_role
BEFORE INSERT OR UPDATE OF inspector_id
ON quality_test
FOR EACH ROW
EXECUTE FUNCTION public.tg_check_inspector_role();
