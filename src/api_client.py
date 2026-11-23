"""
=====================================================================
Purpose: Reusable client for the data.gov.sg Datastore Search API
         (Group 2 HDB project, Task 1 - issue #3).
         - Authenticates with an API key sent in the `x-api-key` header
         - Pages through a dataset with limit / offset until all rows are read
         - Respects the rate limit (throttle) and retries 429 / 5xx errors
         - Saves every raw JSON page to disk, so runs are reproducible and
           can resume after an error without calling the API again
Input:   DATA_GOV_SG_API_KEY in the project's .env file (never hard-coded)
         resource_id of a dataset, e.g. 'd_8b84c4ee58e3cfc0ece0d773c8ca6abc'
Output:  list of record dicts / pandas DataFrame; raw pages as JSON files
Usage:
    from api_client import DataGovClient
    client = DataGovClient()
    df = client.fetch_all_df('d_8b84c4ee58e3cfc0ece0d773c8ca6abc', raw_dir='../data/raw/resale_pages')
=====================================================================
"""
import json
import os
import time
from pathlib import Path

import pandas as pd
import requests
from dotenv import find_dotenv, load_dotenv
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

BASE_URL = 'https://data.gov.sg/api/action/datastore_search'   # Datastore Search endpoint
USER_AGENT = 'group2-hdb-resale/1.0 (Generation JDEA student project)'


class DataGovClient:
    """Small, reusable wrapper around data.gov.sg datastore_search."""

    def __init__(self, api_key=None, min_interval=1.3, timeout=60, max_retries=5):
        """
        api_key      : optional; if None it is read from DATA_GOV_SG_API_KEY in .env
        min_interval : seconds between calls (1.3 s keeps under 8 calls / 10 s for a dev key)
        timeout      : seconds to wait for one response
        max_retries  : retries for 429 (rate limit) and 5xx (server) errors
        """
        load_dotenv(find_dotenv(usecwd=True))                 # finds .env in this or a parent folder
        self.api_key = api_key or os.getenv('DATA_GOV_SG_API_KEY')
        self.min_interval = min_interval
        self.timeout = timeout
        self._last_call = 0.0
        self.calls = 0                                         # API calls made (for the log)

        self.session = requests.Session()                      # re-uses the connection
        self.session.headers.update({'Accept': 'application/json', 'User-Agent': USER_AGENT})
        if self.api_key:
            self.session.headers['x-api-key'] = self.api_key   # authentication header

        retry = Retry(total=max_retries, backoff_factor=2,     # waits 2, 4, 8, 16 ... s
                      status_forcelist=[429, 500, 502, 503, 504],
                      allowed_methods=['GET'], respect_retry_after_header=True)
        self.session.mount('https://', HTTPAdapter(max_retries=retry))

    # ------------------------------------------------------------------
    @property
    def authenticated(self):
        """True if an API key was found (the key itself is never printed)."""
        return bool(self.api_key)

    def headers_for_docs(self):
        """Request headers with the key masked - safe to print or document."""
        h = dict(self.session.headers)
        if 'x-api-key' in h:
            h['x-api-key'] = '***hidden***'
        return h

    def _throttle(self):
        """Sleep so that calls are at least `min_interval` seconds apart."""
        wait = self.min_interval - (time.time() - self._last_call)
        if wait > 0:
            time.sleep(wait)
        self._last_call = time.time()

    # ------------------------------------------------------------------
    def get_page(self, resource_id, limit=100, offset=0, sort=None, **extra):
        """
        One GET call. Returns the full JSON response (dict).
        Raises an error if the HTTP status is not 2xx or success is False.
        """
        params = {'resource_id': resource_id, 'limit': limit, 'offset': offset, **extra}
        if sort:
            params['sort'] = sort
        self._throttle()
        resp = self.session.get(BASE_URL, params=params, timeout=self.timeout)
        self.calls += 1
        resp.raise_for_status()                                # 4xx / 5xx after retries -> error
        data = resp.json()
        if not data.get('success', False):
            raise RuntimeError(f"API returned success=False: {data.get('error')}")
        return data

    def schema(self, resource_id):
        """Field names and types + total row count, from a 1-row call (for docs/api_endpoints.md)."""
        data = self.get_page(resource_id, limit=1)
        fields = pd.DataFrame(data['result']['fields'])        # columns: type, id
        return fields, data['result'].get('total')

    # ------------------------------------------------------------------
    def fetch_all(self, resource_id, page_size=10000, raw_dir=None, sort='_id asc', max_pages=None, verbose=True):
        """
        Page through the whole dataset with limit / offset.
        page_size : rows asked per call (the API may return fewer - handled)
        raw_dir   : folder to save each raw page as JSON; existing pages are re-used (resume)
        sort      : stable order for paging; set None if the API rejects it
        max_pages : stop early (for testing)
        Returns a list of record dicts.
        """
        raw_dir = Path(raw_dir) if raw_dir else None
        if raw_dir:
            raw_dir.mkdir(parents=True, exist_ok=True)

        records, offset, page_no, total = [], 0, 0, None
        while True:
            page_no += 1
            page_file = raw_dir / f'{resource_id}_offset{offset:07d}_limit{page_size}.json' if raw_dir else None

            if page_file and page_file.exists():                    # resume: read saved page, no API call
                data = json.loads(page_file.read_text(encoding='utf-8'))
                source = 'disk'
            else:
                data = self.get_page(resource_id, limit=page_size, offset=offset, sort=sort)
                source = 'api'
                if page_file:                                       # save raw response for reproducibility
                    page_file.write_text(json.dumps(data, ensure_ascii=False), encoding='utf-8')

            result = data['result']
            batch = result['records']
            total = result.get('total', total)
            records.extend(batch)
            offset += len(batch)                                    # move by what was really returned

            if verbose:
                total_txt = f'{total:,}' if total is not None else '?'
                print(f'page {page_no:3d} ({source}): +{len(batch):,} rows -> {offset:,} / {total_txt}')

            if not batch or (total is not None and offset >= total):
                break
            if max_pages and page_no >= max_pages:
                print('Stopped early (max_pages).')
                break
        return records

    def fetch_all_df(self, resource_id, **kwargs):
        """fetch_all() returned as a DataFrame."""
        return pd.DataFrame(self.fetch_all(resource_id, **kwargs))
