from __future__ import annotations

from src.controllers.database import DatabaseController


class WorkerService:
    @staticmethod
    def get_orders(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM workers.get_orders() ORDER BY created_at DESC",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def set_order_status(login: str, order_id: int, status: str):
        db = DatabaseController()
        return db.execute(
            "SELECT workers.set_order_status(%s, %s::public.order_status)",
            params=[order_id, status],
            executor_username=login,
            fetch_count=0,
            require_session=True,
        )

    @staticmethod
    def create_batch(login: str, product_name: str, batch_code: str, qty_kg: float):
        db = DatabaseController()
        return db.execute(
            "SELECT workers.create_batch(%s, %s, %s) AS batch_id",
            params=[product_name, batch_code, qty_kg],
            executor_username=login,
            fetch_count=1,
            require_session=True,
        )

    @staticmethod
    def get_batches(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM workers.get_batches() ORDER BY prod_date DESC, code",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def set_batch_status(login: str, batch_code: str, status: str):
        db = DatabaseController()
        return db.execute(
            "SELECT workers.set_batch_status(%s, %s::public.batch_status)",
            params=[batch_code, status],
            executor_username=login,
            fetch_count=0,
            require_session=True,
        )

    @staticmethod
    def record_quality_test(login: str, batch_code: str, result: str, ph, moisture_pct, comments):
        db = DatabaseController()
        return db.execute(
            "SELECT workers.record_quality_test(%s, %s::public.test_result, %s, %s, %s) AS test_id",
            params=[batch_code, result, ph, moisture_pct, comments],
            executor_username=login,
            fetch_count=1,
            require_session=True,
        )

    @staticmethod
    def get_quality_tests(login: str, batch_code: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM workers.get_quality_tests(%s) ORDER BY created_at DESC",
            params=[batch_code],
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def get_supplies(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM workers.get_supplies() ORDER BY supplier_name, raw_material_name",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def upsert_supply(login: str, supplier_name: str, raw_material_name: str, unit: str, cost_numeric: float, lead_time_days: int):
        db = DatabaseController()
        return db.execute(
            "SELECT workers.upsert_supply(%s, %s, %s, %s, %s) AS supply_id",
            params=[supplier_name, raw_material_name, unit, cost_numeric, lead_time_days],
            executor_username=login,
            fetch_count=1,
            require_session=True,
        )
