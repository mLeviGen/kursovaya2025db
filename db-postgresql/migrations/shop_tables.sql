CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS auth_user (
  id            int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username      varchar(50) NOT NULL UNIQUE,
  password_hash text NOT NULL,
  user_type     varchar(10) NOT NULL CHECK (user_type IN ('CUSTOMER','EMPLOYEE','ADMIN')),
  customer_id   int REFERENCES customer(id) ON DELETE CASCADE,
  employee_id   int REFERENCES employee(id) ON DELETE CASCADE,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),

  CHECK (
    (user_type = 'CUSTOMER' AND customer_id IS NOT NULL AND employee_id IS NULL) OR
    (user_type IN ('EMPLOYEE','ADMIN') AND employee_id IS NOT NULL AND customer_id IS NULL) OR
    (user_type = 'ADMIN' AND employee_id IS NULL AND customer_id IS NULL)
  )
);

ALTER TABLE customer_order
  ADD COLUMN IF NOT EXISTS channel varchar(10) NOT NULL DEFAULT 'B2C'
    CHECK (channel IN ('B2C','B2B')),
  ADD COLUMN IF NOT EXISTS created_by_user_id int REFERENCES auth_user(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();
