"""
Simple in-memory cache for BigQuery results
"""
from datetime import datetime, timedelta
from typing import Any, Dict, Optional
import hashlib
import json
import logging

logger = logging.getLogger(__name__)


class SimpleCache:
    """In-memory cache with TTL support"""
    
    def __init__(self):
        self._cache: Dict[str, Dict[str, Any]] = {}
    
    def _generate_key(self, query: str, params: Dict[str, Any]) -> str:
        """Generate cache key from query and params"""
        cache_data = f"{query}:{json.dumps(params, sort_keys=True)}"
        return hashlib.md5(cache_data.encode()).hexdigest()
    
    def get(self, query: str, params: Dict[str, Any]) -> Optional[Any]:
        """Get cached result if not expired"""
        key = self._generate_key(query, params)
        
        if key in self._cache:
            entry = self._cache[key]
            if datetime.now() < entry['expires_at']:
                logger.info(f"Cache HIT for key: {key[:8]}...")
                return entry['data']
            else:
                # Expired, remove it
                del self._cache[key]
                logger.info(f"Cache EXPIRED for key: {key[:8]}...")
        
        logger.info(f"Cache MISS for key: {key[:8]}...")
        return None
    
    def set(self, query: str, params: Dict[str, Any], data: Any, ttl_seconds: int = 300):
        """Cache result with TTL"""
        key = self._generate_key(query, params)
        self._cache[key] = {
            'data': data,
            'expires_at': datetime.now() + timedelta(seconds=ttl_seconds),
            'cached_at': datetime.now()
        }
        logger.info(f"Cached result for key: {key[:8]}... (TTL: {ttl_seconds}s)")
    
    def clear(self):
        """Clear all cache"""
        count = len(self._cache)
        self._cache.clear()
        logger.info(f"Cleared {count} cache entries")
    
    def stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total = len(self._cache)
        expired = sum(1 for entry in self._cache.values() 
                     if datetime.now() >= entry['expires_at'])
        
        return {
            'total_entries': total,
            'active_entries': total - expired,
            'expired_entries': expired
        }


# Global cache instance
_cache = SimpleCache()


def get_cache() -> SimpleCache:
    """Get global cache instance"""
    return _cache
