-- 1. Очистка (для перезапуска)
DROP SCHEMA IF EXISTS "private" CASCADE;
DROP SCHEMA IF EXISTS "admin" CASCADE;
DROP SCHEMA IF EXISTS "authorized" CASCADE;
DROP SCHEMA IF EXISTS "workers" CASCADE;

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


-- 4. Настройка прав (Security-centric design)
-- Забираем права у PUBLIC на всё
REVOKE ALL ON SCHEMA "private" FROM PUBLIC;
REVOKE ALL ON SCHEMA "admin" FROM PUBLIC;
REVOKE ALL ON SCHEMA "authorized" FROM PUBLIC;
REVOKE ALL ON SCHEMA "workers" FROM PUBLIC;
REVOKE ALL ON SCHEMA "public" FROM PUBLIC; -- Даже на public забираем для безопасности

-- Выдаем точечно
-- Admin
GRANT USAGE ON SCHEMA "admin" TO "admin";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "admin" TO "admin";
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA "admin" TO "admin";

-- Client
GRANT USAGE ON SCHEMA "authorized" TO "admin", "client";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "authorized" TO "admin", "client";
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA "authorized" TO "admin", "client";

-- Employee
GRANT USAGE ON SCHEMA "workers" TO "admin", "employee";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "workers" TO "admin", "employee";
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA "workers" TO "admin", "employee";

-- Public (доступно всем авторизованным ролям)
GRANT USAGE ON SCHEMA "public" TO "guest", "client", "employee", "admin";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "public" TO "guest", "client", "employee", "admin";
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA "public" TO "guest", "client", "employee", "admin";


-- 5. Технический пользователь
CREATE USER "cheese_guest" WITH PASSWORD 'guest_pass';
GRANT "guest" TO "cheese_guest";