"""
Redis service for temporary OTP state, rate limiting, and resend cooldowns.
Includes resilient in-memory fallback if Redis daemon is not running.
"""

import json
import time
from typing import Any, Dict, Optional, Tuple
import redis

from app.config.settings import settings
from app.utils.logger import logger


class RedisOtpService:
    def __init__(self, redis_url: Optional[str] = None):
        self.redis_url = redis_url or settings.REDIS_URL
        self._client: Optional[redis.Redis] = None
        self._in_memory_store: Dict[str, Dict[str, Any]] = {}
        self._connect()

    def _connect(self):
        try:
            client = redis.from_url(
                self.redis_url,
                decode_responses=True,
                socket_timeout=1.5,
                socket_connect_timeout=1.5,
            )
            # Test connection
            client.ping()
            self._client = client
            logger.info("Connected successfully to Redis server.")
        except Exception as e:
            self._client = None
            logger.warning(
                f"Redis server unavailable ({e}). Using resilient in-memory temporary cache."
            )

    def _get_client(self) -> Optional[redis.Redis]:
        if self._client:
            try:
                self._client.ping()
                return self._client
            except Exception:
                self._client = None
        return None

    # --- Resend Cooldown (30-60s) ---
    def check_resend_cooldown(self, phone: str) -> Optional[int]:
        """Returns remaining cooldown seconds if restricted, or None if clear."""
        key = f"otp:cooldown:{phone}"
        client = self._get_client()
        if client:
            ttl = client.ttl(key)
            return ttl if ttl > 0 else None
        else:
            item = self._in_memory_store.get(key)
            if item and item.get("expires_at", 0) > time.time():
                return int(item["expires_at"] - time.time())
            return None

    def set_resend_cooldown(self, phone: str, seconds: int = 30):
        key = f"otp:cooldown:{phone}"
        client = self._get_client()
        if client:
            client.setex(key, seconds, "1")
        else:
            self._in_memory_store[key] = {
                "val": "1",
                "expires_at": time.time() + seconds,
            }

    # --- Hourly Request Throttling (Max 5 OTP requests / hour) ---
    def check_and_increment_hourly_rate(
        self, phone: str, max_requests: int = 5, window_seconds: int = 3600
    ) -> Tuple[bool, int]:
        """
        Returns (is_allowed, current_count).
        If allowed, increments counter.
        """
        key = f"otp:hourly:{phone}"
        client = self._get_client()
        if client:
            count = client.incr(key)
            if count == 1:
                client.expire(key, window_seconds)
            is_allowed = count <= max_requests
            return is_allowed, count
        else:
            now = time.time()
            item = self._in_memory_store.get(key)
            if not item or item.get("expires_at", 0) <= now:
                self._in_memory_store[key] = {
                    "count": 1,
                    "expires_at": now + window_seconds,
                }
                return True, 1
            else:
                item["count"] += 1
                is_allowed = item["count"] <= max_requests
                return is_allowed, item["count"]

    # --- OTP State (request_id, provider, expiry, attempts) ---
    def save_otp_state(
        self,
        phone: str,
        request_id: str,
        otp_hash: str,
        role: str,
        ttl_seconds: int = 300,
    ):
        key = f"otp:kriyo:{phone}"
        state_data = {
            "request_id": request_id,
            "provider": "msg91",
            "role": role,
            "otp_hash": otp_hash,
            "created_at": time.time(),
            "expires_at": time.time() + ttl_seconds,
            "attempt_count": 0,
            "resend_count": 0,
        }
        client = self._get_client()
        if client:
            client.setex(key, ttl_seconds, json.dumps(state_data))
        else:
            self._in_memory_store[key] = state_data

    def get_otp_state(self, phone: str) -> Optional[Dict[str, Any]]:
        key = f"otp:kriyo:{phone}"
        client = self._get_client()
        if client:
            val = client.get(key)
            if val:
                return json.loads(val)
            return None
        else:
            item = self._in_memory_store.get(key)
            if item and item.get("expires_at", 0) > time.time():
                return item
            return None

    def increment_attempt_count(self, phone: str) -> int:
        key = f"otp:kriyo:{phone}"
        state = self.get_otp_state(phone)
        if not state:
            return 0
        state["attempt_count"] = state.get("attempt_count", 0) + 1

        client = self._get_client()
        if client:
            ttl = client.ttl(key)
            if ttl > 0:
                client.setex(key, ttl, json.dumps(state))
        else:
            self._in_memory_store[key] = state
        return state["attempt_count"]

    def clear_otp_state(self, phone: str):
        key = f"otp:kriyo:{phone}"
        client = self._get_client()
        if client:
            client.delete(key)
        else:
            self._in_memory_store.pop(key, None)


redis_otp_service = RedisOtpService()
