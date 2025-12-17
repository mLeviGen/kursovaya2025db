CREATE OR REPLACE FUNCTION private.tg_calculate_batch_best_before()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
DECLARE
    v_aging_days INT;
BEGIN
    SELECT aging_days INTO v_aging_days
    FROM private.product
    WHERE id = NEW.product_id;

    IF NEW.prod_date IS NULL THEN
        NEW.prod_date := CURRENT_DATE;
    END IF;

    IF v_aging_days IS NOT NULL THEN
        NEW.best_before := NEW.prod_date + make_interval(days => v_aging_days);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_batch_dates
BEFORE INSERT OR UPDATE OF product_id, prod_date
ON private.batch
FOR EACH ROW
EXECUTE FUNCTION private.tg_calculate_batch_best_before();

CREATE OR REPLACE FUNCTION private.tg_update_batch_status()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.result = 'pass' THEN
        UPDATE private.batch 
        SET status = 'released' 
        WHERE id = NEW.batch_id;
    ELSIF NEW.result = 'fail' THEN
        UPDATE private.batch 
        SET status = 'rejected' 
        WHERE id = NEW.batch_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_update_batch_status
AFTER INSERT OR UPDATE OF result
ON private.quality_test
FOR EACH ROW
EXECUTE FUNCTION private.tg_update_batch_status();


CREATE OR REPLACE FUNCTION private.tg_set_order_item_price()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
DECLARE
    v_current_price NUMERIC(10,2);
    v_is_active BOOLEAN;
BEGIN
    SELECT base_price, is_active INTO v_current_price, v_is_active
    FROM private.product
    WHERE id = NEW.product_id;

    IF NOT v_is_active THEN
        RAISE EXCEPTION 'Product % is not active and cannot be ordered', NEW.product_id;
    END IF;

    IF NEW.unit_price IS NULL THEN
        NEW.unit_price := v_current_price;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_item_price_before_insert
BEFORE INSERT ON private.order_item
FOR EACH ROW
EXECUTE FUNCTION private.tg_set_order_item_price();


CREATE OR REPLACE FUNCTION private.tg_update_order_total()
RETURNS TRIGGER
SECURITY DEFINER
AS $$
DECLARE
    v_order_id BIGINT;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;

    UPDATE private.orders
    SET total_price = (
        SELECT COALESCE(SUM(qty * unit_price), 0)
        FROM private.order_item
        WHERE order_id = v_order_id
    )
    WHERE id = v_order_id;

    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_total_after_change
AFTER INSERT OR UPDATE OR DELETE ON private.order_item
FOR EACH ROW
EXECUTE FUNCTION private.tg_update_order_total();