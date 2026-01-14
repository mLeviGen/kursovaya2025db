from __future__ import annotations

import threading
import time
from collections import deque
from dataclasses import dataclass
from typing import Deque, Dict, Iterable, Optional, Tuple

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response


@dataclass(frozen=True)
class RateLimitRule:
    method: str
    path_prefix: str
    limit: int
    window_sec: int
    name: str


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Very small in-memory rate limiter.

    Notes:
    - per-IP, per-rule sliding window
    - good enough for a coursework deployment; for multi-replica production use Redis, etc.
    """

    def __init__(self, app, rules: Optional[Iterable[RateLimitRule]] = None):
        super().__init__(app)
        self._rules = list(rules or [])
        self._hits: Dict[str, Deque[float]] = {}
        self._lock = threading.Lock()

    def _match_rule(self, request: Request) -> Optional[RateLimitRule]:
        path = request.url.path
        method = request.method.upper()
        for r in self._rules:
            if method == r.method and path.startswith(r.path_prefix):
                return r
        return None

    async def dispatch(self, request: Request, call_next) -> Response:
        rule = self._match_rule(request)
        if rule is None:
            return await call_next(request)

        ip = request.client.host if request.client else "unknown"
        key = f"{ip}:{rule.name}"

        now = time.time()
        window_start = now - rule.window_sec

        with self._lock:
            dq = self._hits.get(key)
            if dq is None:
                dq = deque()
                self._hits[key] = dq

            while dq and dq[0] <= window_start:
                dq.popleft()

            if len(dq) >= rule.limit:
                retry_after = int(max(1, dq[0] + rule.window_sec - now)) if dq else rule.window_sec
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too many requests"},
                    headers={"Retry-After": str(retry_after)},
                )

            dq.append(now)

        return await call_next(request)
