from __future__ import annotations

from src.controllers.database import DatabaseController


class PublicService:
    @staticmethod
    def get_products():
        db = DatabaseController()
        db.connect()
        return db.execute("SELECT * FROM public.products_view ORDER BY name", fetch_count=-1)

    @staticmethod
    def get_batches():
        db = DatabaseController()
        db.connect()
        return db.execute("SELECT * FROM public.batches_public_view ORDER BY prod_date DESC, code", fetch_count=-1)
