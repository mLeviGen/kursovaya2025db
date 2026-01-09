from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable

import psycopg
from psycopg.rows import dict_row

from config import DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD


@dataclass
class _Conn:
    conn: psycopg.Connection


class DatabaseController:
    _instance = None
    connections: dict[str, _Conn]

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.connections = {}
        return cls._instance

    def connect(self, username: str | None = None, password: str | None = None) -> None:
        if username is None or password is None:
            username, password = DB_USER, DB_PASSWORD

        if username in self.connections:
            # already connected
            return

        conn = psycopg.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=username,
            password=password,
            row_factory=dict_row,
        )
        self.connections[username] = _Conn(conn=conn)

    def disconnect(self, username: str) -> None:
        if username not in self.connections:
            return
        c = self.connections.pop(username)
        try:
            c.conn.close()
        except Exception:
            pass

    def is_connected(self, username: str) -> bool:
        return username in self.connections

    def execute(
        self,
        query: str,
        params: Iterable[Any] | None = None,
        fetch_count: int = -1,
        executor_username: str | None = None,
        require_session: bool = False,
    ) -> Exception | Any:
        if executor_username is None:
            executor_username = DB_USER

        if executor_username not in self.connections:
            if require_session:
                return RuntimeError("No active DB session for this user. Please login again.")
            # fallback to guest
            executor_username = DB_USER
            if executor_username not in self.connections:
                self.connect()

        conn = self.connections[executor_username].conn

        try:
            with conn.cursor() as cur:
                cur.execute(query, params)
                if fetch_count == 1:
                    result = cur.fetchone()
                elif fetch_count == 0:
                    result = None
                elif fetch_count == -1:
                    result = cur.fetchall()
                else:
                    result = cur.fetchmany(fetch_count)
            conn.commit()
            return result
        except Exception as e:
            conn.rollback()
            return e
