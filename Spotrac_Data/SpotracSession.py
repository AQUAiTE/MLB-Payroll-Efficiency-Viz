import datetime
import hashlib
import json
from pathlib import Path
from time import sleep, time
from typing import Any, Optional

from curl_cffi import requests
import Singleton


class SpotracSession(Singleton.Singleton):
    """
    Spotrac requests a 10 second crawl delay (6 requests per minute)
    so we will limit to that for now
    """
    def __init__(
        self,
        crawl_delay_seconds: int = 10,
        cache_dir: str = '.spotrac_cache',
        cache_ttl_seconds: int = 60 * 60 * 24 * 30
    ) -> None:
        self.crawl_delay_seconds = crawl_delay_seconds
        self.cache_ttl_seconds = cache_ttl_seconds
        self.last_request: Optional[datetime.datetime] = None
        self.session = requests.Session()

        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def get(self, url: str, **kwargs: Any) -> requests.Response:
        cache_path = self._cache_path(url)

        # Cached responses instead of requesting again
        if self._cache_valid(cache_path):
            return self._cache_load(cache_path, url)

        if self.last_request is not None:
            delta = (datetime.datetime.now() - self.last_request).total_seconds()
            sleep_length = self.crawl_delay_seconds - delta
            if sleep_length > 0:
                sleep(sleep_length)

        self.last_request = datetime.datetime.now()

        try:
            res = self.session.get(url, impersonate="chrome", **kwargs)
            res.raise_for_status()
            self._cache_save(cache_path, res)
            return res
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Spotrac request failed: {e}") from e
    
    def _cache_path(self, url: str) -> Path:
        """
        Names the cache file based on the URL we use
        """
        digest = hashlib.sha256(url.encode('utf-8')).hexdigest()
        return self.cache_dir / '{}.cache'.format(digest)
    
    def _cache_valid(self, path: Path) -> bool:
        """
        Validate the cache
        """
        if not path.exists():
            return False
        age = time() - path.stat().st_mtime
        return age < self.cache_ttl_seconds
    
    def _cache_save(self, path: Path, res: requests.Response) -> None:
        """
        Saves the response to the cache
        """
        cache_data = {
            'status_code': res.status_code,
            'headers': dict(res.headers),
            'content': res.content.hex()
        }
        path.write_text(json.dumps(cache_data))
    
    def _cache_load(self, path: Path, url: str) -> requests.Response:
        """
        Loads the cached response
        """
        cache_data = json.loads(path.read_text())
        res = requests.Response()
        res.status_code = cache_data['status_code']
        res.headers.update(cache_data['headers'])
        res._content = bytes.fromhex(cache_data['content'])
        res.url = url
        return res
