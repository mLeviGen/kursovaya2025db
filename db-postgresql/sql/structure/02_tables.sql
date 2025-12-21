CREATE TABLE private.users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login VARCHAR(32) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE CHECK (public.check_email(email)),
    phone VARCHAR(32) CHECK (public.check_tel(phone)),
    password_hash VARCHAR(512) NOT NULL,
    
    first_name VARCHAR(32) NOT NULL,
    last_name VARCHAR(32) NOT NULL,
    
    role public.user_role_type NOT NULL DEFAULT 'client',
    
    hire_date DATE DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.supplier (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(32) CHECK (public.check_tel(phone)),
    email VARCHAR(128) CHECK (public.check_email(email)),
    address TEXT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.raw_material (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    unit VARCHAR(10) NOT NULL, -- кг, л, г
    shelf_life_days INT CHECK (shelf_life_days > 0),
    allergen_flag BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.supply (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id INT NOT NULL REFERENCES private.supplier(id) ON DELETE CASCADE,
    raw_material_id INT NOT NULL REFERENCES private.raw_material(id) ON DELETE CASCADE,
    cost_numeric NUMERIC(10,2) NOT NULL CHECK (cost_numeric >= 0),
    lead_time_days INT CHECK (lead_time_days >= 0),
    
    UNIQUE(supplier_id, raw_material_id)
);

CREATE TABLE private.recipe (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    yield_pct INT CHECK (yield_pct > 0 AND yield_pct <= 100),
    author_id BIGINT REFERENCES private.users(id) ON DELETE SET NULL, -- Если уволили, рецепт остается
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.recipe_ingredient (
    recipe_id INT NOT NULL REFERENCES private.recipe(id) ON DELETE CASCADE,
    raw_material_id INT NOT NULL REFERENCES private.raw_material(id) ON DELETE RESTRICT,
    qty NUMERIC(10,3) NOT NULL CHECK (qty > 0),
    unit VARCHAR(10), 
    PRIMARY KEY (recipe_id, raw_material_id)
);

CREATE TABLE private.product (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category public.cheese_category NOT NULL,
    aging_days INT NOT NULL CHECK (aging_days >= 0),
    base_price NUMERIC(10,2) NOT NULL CHECK (base_price >= 0),
    recipe_id INT REFERENCES private.recipe(id),
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.batch (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    product_id INT NOT NULL REFERENCES private.product(id),
    prod_date DATE NOT NULL DEFAULT CURRENT_DATE,
    best_before DATE, 
    qty_kg NUMERIC(10,2) NOT NULL CHECK (qty_kg > 0),
    status public.batch_status NOT NULL DEFAULT 'aging',
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.quality_test (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_id BIGINT NOT NULL REFERENCES private.batch(id) ON DELETE CASCADE,
    inspector_id BIGINT REFERENCES private.users(id) ON DELETE SET NULL,
    test_date TIMESTAMP DEFAULT NOW(),
    
    ph NUMERIC(3,1),
    moisture_pct NUMERIC(4,1),
    result public.test_result NOT NULL, -- PASS/FAIL
    comments TEXT
);

CREATE TABLE private.orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES private.users(id) ON DELETE CASCADE,
    status public.order_status NOT NULL DEFAULT 'new',
    total_price NUMERIC(10,2) DEFAULT 0,
    comments TEXT,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    changed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE private.order_item (
    order_id BIGINT NOT NULL REFERENCES private.orders(id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES private.product(id) ON DELETE RESTRICT,
    qty INT NOT NULL CHECK (qty > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0), -- Цена на момент покупки
    
    PRIMARY KEY (order_id, product_id)
);

CREATE TRIGGER update_users_modtime BEFORE UPDATE ON private.users 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();

CREATE TRIGGER update_supplier_modtime BEFORE UPDATE ON private.supplier 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();

CREATE TRIGGER update_recipe_modtime BEFORE UPDATE ON private.recipe 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();

CREATE TRIGGER update_product_modtime BEFORE UPDATE ON private.product 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();

CREATE TRIGGER update_batch_modtime BEFORE UPDATE ON private.batch 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();

CREATE TRIGGER update_orders_modtime BEFORE UPDATE ON private.orders 
FOR EACH ROW EXECUTE PROCEDURE public.update_changed_at_column();