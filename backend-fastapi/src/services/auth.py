from __future__ import annotations

from src.controllers.database import DatabaseController
from src.schemas.auth import LoginSchema, RegisterSchema, AdminCreateUserSchema


class AuthService:
    @staticmethod
    def authenticate(data: LoginSchema):
        db = DatabaseController()
        db.connect()

        query = "SELECT * FROM public.authenticate(%s, %s)"
        params = [data.login, data.password]
        return db.execute(query, params=params, fetch_count=1)

    @staticmethod
    def register(data: RegisterSchema):
        db = DatabaseController()
        db.connect()
        query = "CALL public.sign_up(%s, %s, %s, %s, %s, %s)"
        params = [data.login, data.password, data.email, data.phone, data.first_name, data.last_name]
        return db.execute(query, params=params, fetch_count=0)

    @staticmethod
    def logout(login: str):
        db = DatabaseController()
        db.disconnect(login)
        return True


class AdminService:
    @staticmethod
    def create_user(data: AdminCreateUserSchema):
        db = DatabaseController()
        db.connect()
        query = "CALL admin.register_user(%s, %s, %s, %s, %s, %s, %s::public.user_role_type)"
        params = [data.login, data.password, data.email, data.phone, data.first_name, data.last_name, data.role]
        return db.execute(query, params=params, fetch_count=0)
