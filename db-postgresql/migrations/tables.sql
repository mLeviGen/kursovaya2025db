DROP TABLE IF EXISTS quality_test CASCADE;
DROP TABLE IF EXISTS batch CASCADE;
DROP TABLE IF EXISTS recipe_ingredient CASCADE;
DROP TABLE IF EXISTS recipe CASCADE;
DROP TABLE IF EXISTS supply CASCADE;
DROP TABLE IF EXISTS order_item CASCADE;
DROP TABLE IF EXISTS customer_order CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS cheese_product CASCADE;
DROP TABLE IF EXISTS raw_material CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS role CASCADE;

CREATE TABLE role (
  id        int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name      varchar(30) NOT NULL UNIQUE
);

CREATE TABLE employee (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  role_id    int NOT NULL REFERENCES role(id),
  first_name varchar(50) NOT NULL,
  last_name  varchar(50) NOT NULL,
  phone      varchar(20),
  email      varchar(100) UNIQUE,
  hire_date  date NOT NULL DEFAULT current_date
);

CREATE TABLE supplier (
  id      int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name    varchar(100) NOT NULL UNIQUE,
  phone   varchar(20),
  email   varchar(100),
  address text,
  rating  smallint CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE raw_material (
  id              int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name            varchar(50) NOT NULL UNIQUE,
  unit            varchar(10) NOT NULL,
  shelf_life_days int NOT NULL CHECK (shelf_life_days >= 0),
  allergen_flag   boolean NOT NULL DEFAULT false
);

CREATE TABLE supply (
  supplier_id     int NOT NULL REFERENCES supplier(id) ON DELETE CASCADE,
  raw_material_id int NOT NULL REFERENCES raw_material(id) ON DELETE CASCADE,
  cost_numeric    numeric(10,2) NOT NULL CHECK (cost_numeric >= 0),
  lead_time_days  int NOT NULL CHECK (lead_time_days >= 0),
  PRIMARY KEY (supplier_id, raw_material_id)
);

CREATE TABLE recipe (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name        varchar(50) NOT NULL UNIQUE,
  description text,
  yield_pct   real NOT NULL CHECK (yield_pct > 0 AND yield_pct <= 100),
  created_at  timestamptz NOT NULL DEFAULT now(),
  author_id   int REFERENCES employee(id) ON DELETE SET NULL
);

CREATE TABLE recipe_ingredient (
  recipe_id       int NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  raw_material_id int NOT NULL REFERENCES raw_material(id) ON DELETE RESTRICT,
  qty             real NOT NULL CHECK (qty > 0),
  unit            varchar(10) NOT NULL,
  PRIMARY KEY (recipe_id, raw_material_id)
);

CREATE TABLE cheese_product (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name       varchar(50) NOT NULL UNIQUE,
  cheese_type varchar(20) NOT NULL,
  aging_days int NOT NULL DEFAULT 0 CHECK (aging_days >= 0),
  base_price numeric(10,2) NOT NULL CHECK (base_price >= 0),
  recipe_id  int REFERENCES recipe(id) ON DELETE SET NULL,
  is_active  boolean NOT NULL DEFAULT true
);

CREATE TABLE batch (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_id int NOT NULL REFERENCES cheese_product(id) ON DELETE RESTRICT,
  code       varchar(30) NOT NULL UNIQUE,
  prod_date  date NOT NULL,
  qty_kg     real NOT NULL CHECK (qty_kg > 0),
  status     varchar(15) NOT NULL DEFAULT 'PLANNED'
            CHECK (status IN ('PLANNED','IN_PRODUCTION','RELEASED','REJECTED','EXPIRED')),
  best_before date
);

CREATE TABLE quality_test (
  id            int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  batch_id      int NOT NULL REFERENCES batch(id) ON DELETE CASCADE,
  test_date     timestamptz NOT NULL DEFAULT now(),
  ph            real CHECK (ph >= 0 AND ph <= 14),
  moisture_pct  real CHECK (moisture_pct >= 0 AND moisture_pct <= 100),
  micro_bio     varchar(50),
  status        varchar(10) NOT NULL CHECK (status IN ('PASS','FAIL')),
  inspector_id  int REFERENCES employee(id) ON DELETE SET NULL
);

CREATE TABLE customer (
  id         int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  full_name  varchar(100) NOT NULL,
  phone      varchar(20),
  email      varchar(100) UNIQUE,
  address    text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE customer_order (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id int NOT NULL REFERENCES customer(id) ON DELETE CASCADE,
  order_date  date NOT NULL DEFAULT current_date,
  status      varchar(15) NOT NULL DEFAULT 'NEW'
             CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED')),
  comments    text
);

CREATE TABLE order_item (
  order_id   int NOT NULL REFERENCES customer_order(id) ON DELETE CASCADE,
  product_id int NOT NULL REFERENCES cheese_product(id) ON DELETE RESTRICT,
  qty        real NOT NULL CHECK (qty > 0),
  unit_price numeric(10,2),
  PRIMARY KEY (order_id, product_id)
);

CREATE INDEX idx_customer_order_date ON customer_order(order_date);
CREATE INDEX idx_order_item_product ON order_item(product_id);
CREATE INDEX idx_batch_product ON batch(product_id);
CREATE INDEX idx_quality_test_batch ON quality_test(batch_id);
