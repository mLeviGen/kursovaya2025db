from __future__ import annotations

from src.controllers.database import DatabaseController


class AdminService:
    @staticmethod
    def get_users(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM admin.users_view ORDER BY id",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def clients_stats(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM admin.clients_stats_view ORDER BY total_spent_money DESC NULLS LAST",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def product_sales(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM admin.product_sales_view ORDER BY revenue DESC NULLS LAST",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def production_stats(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM admin.production_stats_view ORDER BY total_kg_produced DESC NULLS LAST",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def quality_log(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM admin.quality_log_view ORDER BY test_date DESC",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )
