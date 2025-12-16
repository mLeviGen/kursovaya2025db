DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cheese_admin') THEN
    CREATE ROLE cheese_admin LOGIN PASSWORD 'change_me_admin';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cheese_app') THEN
    CREATE ROLE cheese_app LOGIN PASSWORD 'change_me_app';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cheese_readonly') THEN
    CREATE ROLE cheese_readonly LOGIN PASSWORD 'change_me_ro';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'cheese_readwrite') THEN
    CREATE ROLE cheese_readwrite LOGIN PASSWORD 'change_me_rw';
  END IF;
END $$;
