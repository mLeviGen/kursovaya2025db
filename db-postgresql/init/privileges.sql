-- запретить всем подряд создавать в public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

DO $$
DECLARE dbname text := current_database();
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO cheese_admin, cheese_app, cheese_readonly, cheese_readwrite', dbname);
END $$;

GRANT USAGE ON SCHEMA public TO cheese_admin, cheese_app, cheese_readonly, cheese_readwrite;

-- readonly
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cheese_readonly;

-- readwrite
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cheese_readwrite;

-- приложению прямой доступ к таблицам не нужен (логика через функции)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM cheese_app;

-- на будущее (новые таблицы)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO cheese_readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO cheese_readwrite;
