import datetime
from time import sleep
from typing import Any, Optional

from curl_cffi import requests
import Singleton


class SpotracSession(Singleton.Singleton):
    """
    Spotrac requests a 10 second crawl delay (6 requests per minute)
    so we will limit to that for now
    """

    def __init__(self, crawl_delay_seconds: int = 10) -> None:
        self.crawl_delay_seconds = crawl_delay_seconds
        self.last_request: Optional[datetime.datetime] = None
        self.session = requests.Session()

    def get(self, url: str, **kwargs: Any) -> requests.Response:
        if self.last_request is not None:
            delta = (datetime.datetime.now() - self.last_request).total_seconds()
            sleep_length = self.crawl_delay_seconds - delta
            if sleep_length > 0:
                sleep(sleep_length)

        self.last_request = datetime.datetime.now()

        try:
            resp = self.session.get(
                url,
                impersonate="chrome",
                **kwargs
            )
            resp.raise_for_status()
            return resp
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Spotrac request failed: {e}") from e
