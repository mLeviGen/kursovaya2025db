from __future__ import annotations

from typing import AsyncIterator

from psycopg_pool import AsyncConnectionPool
from psycopg import AsyncConnection

from .config import settings

pool: AsyncConnectionPool | None = None


async def open_pool() -> None:
    global pool
    if pool is None:
        pool = AsyncConnectionPool(
            conninfo=settings.database_url,
            min_size=1,
            max_size=10,
            timeout=10,
        )
        await pool.open()


async def close_pool() -> None:
    global pool
    if pool is not None:
        await pool.close()
        pool = None


async def get_conn() -> AsyncIterator[AsyncConnection]:
    if pool is None:
        raise RuntimeError("DB pool is not initialized")
    async with pool.connection() as conn:
        yield conn
