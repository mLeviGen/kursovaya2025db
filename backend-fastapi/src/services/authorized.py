from __future__ import annotations

import json

from src.controllers.database import DatabaseController


class AuthorizedService:
    @staticmethod
    def get_my_orders(login: str):
        db = DatabaseController()
        return db.execute(
            "SELECT * FROM authorized.get_my_orders() ORDER BY created_at DESC",
            executor_username=login,
            fetch_count=-1,
            require_session=True,
        )

    @staticmethod
    def make_order(login: str, items: list[dict], comments: str | None):
        db = DatabaseController()
        # transform to jsonb expected format: [{product, qty}, ...]
        payload = json.dumps(items, ensure_ascii=False)
        return db.execute(
            "SELECT authorized.make_order(%s::jsonb, %s) AS order_id",
            params=[payload, comments],
            executor_username=login,
            fetch_count=1,
            require_session=True,
        )

    @staticmethod
    def cancel_my_order(login: str, order_id: int):
        db = DatabaseController()
        return db.execute(
            "SELECT authorized.cancel_my_order(%s)",
            params=[order_id],
            executor_username=login,
            fetch_count=0,
            require_session=True,
        )
