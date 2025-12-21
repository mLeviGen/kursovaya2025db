DROP TYPE IF EXISTS public.user_role_type CASCADE;
DROP TYPE IF EXISTS public.batch_status CASCADE;
DROP TYPE IF EXISTS public.order_status CASCADE;
DROP TYPE IF EXISTS public.cheese_category CASCADE;
DROP TYPE IF EXISTS public.test_result CASCADE;

CREATE TYPE public.user_role_type AS ENUM (
    'admin', 
    'technologist', 
    'inspector', 
    'manager', 
    'client'
);

CREATE TYPE public.batch_status AS ENUM (
    'aging',      -- созревание
    'released',   -- выпущено в продажу
    'rejected',   -- брак
    'testing'     -- на проверке
);

CREATE TYPE public.order_status AS ENUM (
    'new',        -- новый
    'paid',       -- оплачен
    'shipped',    -- отправлен
    'completed',  -- завершен
    'cancelled'   -- отменен
);

CREATE TYPE public.cheese_category AS ENUM (
    'hard',       -- твердый
    'semi-hard',  -- полутвердый
    'soft',       -- мягкий
    'blue',       -- с плесенью
    'fresh'       -- свежий
);

CREATE TYPE public.test_result AS ENUM (
    'pass', 
    'fail'
);