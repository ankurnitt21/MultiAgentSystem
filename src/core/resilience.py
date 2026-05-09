"""Resilience patterns - Circuit Breaker and Rate Limiter."""

import time
import threading
from enum import Enum
from functools import wraps
from typing import Callable, Any
import structlog

log = structlog.get_logger()


class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreaker:
    """Thread-safe circuit breaker for external service calls."""

    def __init__(self, name: str, failure_threshold: int = 5,
                 recovery_timeout: float = 30.0, expected_exceptions: tuple = (Exception,)):
        self.name = name
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exceptions = expected_exceptions
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._last_failure_time = 0.0
        self._lock = threading.Lock()

    @property
    def state(self) -> CircuitState:
        with self._lock:
            if self._state == CircuitState.OPEN:
                if time.time() - self._last_failure_time >= self.recovery_timeout:
                    self._state = CircuitState.HALF_OPEN
            return self._state

    def record_success(self):
        with self._lock:
            self._failure_count = 0
            if self._state == CircuitState.HALF_OPEN:
                self._state = CircuitState.CLOSED

    def record_failure(self):
        with self._lock:
            self._failure_count += 1
            self._last_failure_time = time.time()
            if self._failure_count >= self.failure_threshold:
                self._state = CircuitState.OPEN
                log.warning("circuit_opened", name=self.name, failures=self._failure_count)

    def call(self, func: Callable, *args, **kwargs) -> Any:
        if self.state == CircuitState.OPEN:
            raise CircuitBreakerOpenError(f"Circuit '{self.name}' is OPEN")
        try:
            result = func(*args, **kwargs)
            self.record_success()
            return result
        except self.expected_exceptions:
            self.record_failure()
            raise


class CircuitBreakerOpenError(Exception):
    pass


class RateLimiter:
    """Token bucket rate limiter."""

    def __init__(self, name: str, max_tokens: int = 30, refill_rate: float = 10.0):
        self.name = name
        self.max_tokens = max_tokens
        self.refill_rate = refill_rate
        self._tokens = float(max_tokens)
        self._last_refill = time.time()
        self._lock = threading.Lock()

    def _refill(self):
        now = time.time()
        elapsed = now - self._last_refill
        self._tokens = min(self.max_tokens, self._tokens + elapsed * self.refill_rate)
        self._last_refill = now

    def acquire(self, tokens: int = 1, timeout: float = 5.0) -> bool:
        deadline = time.time() + timeout
        while True:
            with self._lock:
                self._refill()
                if self._tokens >= tokens:
                    self._tokens -= tokens
                    return True
            if time.time() >= deadline:
                return False
            time.sleep(0.05)

    def call(self, func: Callable, *args, **kwargs) -> Any:
        if not self.acquire():
            raise RateLimitExceededError(f"Rate limit exceeded for '{self.name}'")
        return func(*args, **kwargs)


class RateLimitExceededError(Exception):
    pass


# Pre-configured instances
llm_circuit = CircuitBreaker(name="groq_llm", failure_threshold=5, recovery_timeout=30.0)
llm_rate_limiter = RateLimiter(name="groq_llm", max_tokens=30, refill_rate=10.0)
redis_circuit = CircuitBreaker(name="redis", failure_threshold=3, recovery_timeout=10.0)
db_circuit = CircuitBreaker(name="database", failure_threshold=3, recovery_timeout=15.0)
embedding_circuit = CircuitBreaker(name="embedding", failure_threshold=3, recovery_timeout=20.0)


def resilient_call(func: Callable, *args, circuit: CircuitBreaker | None = None,
                   rate_limiter: RateLimiter | None = None, fallback: Any = None, **kwargs) -> Any:
    """Execute with combined circuit breaker + rate limiter protection."""
    try:
        if rate_limiter and not rate_limiter.acquire():
            if fallback is not None:
                return fallback
            raise RateLimitExceededError(f"Rate limit exceeded for {func.__name__}")
        if circuit:
            return circuit.call(func, *args, **kwargs)
        return func(*args, **kwargs)
    except (CircuitBreakerOpenError, RateLimitExceededError):
        if fallback is not None:
            return fallback
        raise
    except Exception:
        if fallback is not None:
            return fallback
        raise
