-- 1. Очистка (для перезапуска)
DROP SCHEMA IF EXISTS "private" CASCADE;
DROP SCHEMA IF EXISTS "admin" CASCADE;
DROP SCHEMA IF EXISTS "authorized" CASCADE;
DROP SCHEMA IF EXISTS "workers" CASCADE;
DROP SCHEMA IF EXISTS "crypto" CASCADE;

-- Очистка зависимостей перед удалением ролей
-- Используем DO блок, чтобы не получать ошибку, если роль еще не существует
DO $$
BEGIN
    -- Очистка для admin
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin') THEN
        -- Эта команда удаляет все объекты роли и отзывает все её права (в т.ч. на public)
        REASSIGN OWNED BY "admin" TO postgres; -- На всякий случай передаем владение
        DROP OWNED BY "admin";
    END IF;

    -- Очистка для employee
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'employee') THEN
        REASSIGN OWNED BY "employee" TO postgres;
        DROP OWNED BY "employee";
    END IF;

    -- Очистка для client
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'client') THEN
        REASSIGN OWNED BY "client" TO postgres;
        DROP OWNED BY "client";
    END IF;

    -- Очистка для guest
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'guest') THEN
        REASSIGN OWNED BY "guest" TO postgres;
        DROP OWNED BY "guest";
    END IF;
END $$;

-- Дополнительно удаляем всех "прикладных" пользователей (LOGIN роли),
-- которые были созданы через admin.create_psql_user и состоят в группах.
-- Иначе DROP ROLE "client"/"employee"/... упадёт из-за зависимостей (membership).
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT u.rolname
        FROM pg_roles u
        WHERE u.rolcanlogin
          AND u.rolname NOT IN ('postgres', 'cheese_guest')
          AND EXISTS (
              SELECT 1
              FROM pg_auth_members m
              JOIN pg_roles parent ON parent.oid = m.roleid
              WHERE m.member = u.oid
                AND parent.rolname IN ('admin', 'employee', 'client', 'guest')
          )
    LOOP
        EXECUTE FORMAT('DROP USER IF EXISTS %I', r.rolname);
    END LOOP;
END $$;

-- Теперь можно безопасно удалять самих пользователей и роли
DROP USER IF EXISTS "cheese_guest";
DROP ROLE IF EXISTS "admin";
DROP ROLE IF EXISTS "employee";
DROP ROLE IF EXISTS "client";
DROP ROLE IF EXISTS "guest";

-- 2. Создание Ролей
CREATE ROLE "guest" NOLOGIN;
CREATE ROLE "client" NOLOGIN;
CREATE ROLE "employee" NOLOGIN;
CREATE ROLE "admin" NOLOGIN CREATEROLE;

GRANT "client" TO "admin" WITH ADMIN OPTION;
GRANT "employee" TO "admin" WITH ADMIN OPTION;

-- 3. Создание Схем
CREATE SCHEMA "private" AUTHORIZATION "postgres";
CREATE SCHEMA "admin" AUTHORIZATION "postgres";
CREATE SCHEMA "authorized" AUTHORIZATION "postgres";
CREATE SCHEMA "workers" AUTHORIZATION "postgres";
CREATE SCHEMA "crypto" AUTHORIZATION "postgres";

-- Расширения (в отдельной схеме, как в примере "такси")
CREATE EXTENSION IF NOT EXISTS pgcrypto SCHEMA crypto;

-- 4. Настройка прав (Security-centric design)
-- Забираем права у PUBLIC на всё
REVOKE ALL ON SCHEMA "private" FROM PUBLIC;
REVOKE ALL ON SCHEMA "admin" FROM PUBLIC;
REVOKE ALL ON SCHEMA "authorized" FROM PUBLIC;
REVOKE ALL ON SCHEMA "workers" FROM PUBLIC;
REVOKE ALL ON SCHEMA "crypto" FROM PUBLIC;
REVOKE ALL ON SCHEMA "public" FROM PUBLIC; -- Даже на public забираем для безопасности

-- Выдаем точечно
-- Admin
GRANT USAGE ON SCHEMA "admin" TO "admin";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "admin" TO "admin";
-- Client
GRANT USAGE ON SCHEMA "authorized" TO "admin", "client";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "authorized" TO "admin", "client";
-- Employee
GRANT USAGE ON SCHEMA "workers" TO "admin", "employee";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "workers" TO "admin", "employee";
-- Public (доступно всем авторизованным ролям)
GRANT USAGE ON SCHEMA "public" TO "guest", "client", "employee", "admin";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "public" TO "guest", "client", "employee", "admin";
-- Гранты по умолчанию для объектов, которые будут создаваться позже (иначе приходится GRANT'ить каждый раз руками)
-- NOTE: подразумевается, что все объекты создаёт владелец БД/схем (обычно postgres).
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA admin REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA admin GRANT EXECUTE ON FUNCTIONS TO "admin";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA authorized REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA authorized GRANT EXECUTE ON FUNCTIONS TO "admin", "client";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA workers REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA workers GRANT EXECUTE ON FUNCTIONS TO "admin", "employee";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO "guest", "client", "employee", "admin";
-- 5. Технический пользователь
CREATE USER "cheese_guest" WITH PASSWORD 'guest_pass';
GRANT "guest" TO "cheese_guest";