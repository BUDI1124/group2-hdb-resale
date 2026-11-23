# API endpoints, authentication and response schema (Task 1)

Fill this in during Sprint 1 (issue: "Document base URLs, headers, parameters and response schema").

## 1. data.gov.sg – HDB resale flat prices (Jan 2017 onwards)
| Item | Value |
|---|---|
| Base URL | `https://data.gov.sg/api/action/datastore_search` |
| Dataset / resource ID | `d_8b84c4ee58e3cfc0ece0d773c8ca6abc` |
| Method | GET |
| Required headers | API key header: ______ (copy the exact header name from the data.gov.sg API docs) |
| Query parameters | `resource_id`, `limit`, `offset` (paging), others used: ______ |
| Rate limit | ______ |
| Records retrieved | ______ rows, from ______ to ______ (run date ______) |

### Response schema
Paste the printed schema from `00_get_data.ipynb` (top-level keys, `result` keys, field names and types).

| Field | Type | Example | Notes |
|---|---|---|---|
| month | text (YYYY-MM) | | converted to ISO date in 02_clean |
| town | text | | |
| flat_type | text | | |
| block | text | | |
| street_name | text | | |
| storey_range | text | | parsed to low / high / mid floor |
| floor_area_sqm | text → float | | |
| flat_model | text | | |
| lease_commence_date | text → int | | |
| remaining_lease | text | "61 years 04 months" | parsed to years (float) |
| resale_price | text → float | | |

## 2. data.gov.sg – HDB Resale Price Index (quarterly)
| Item | Value |
|---|---|
| Dataset / resource ID | `d_14f63e595975691e7c24a27ae4c07c79` |
| Same base URL, headers and paging as above | |

## 3. SingStat Table Builder (optional)
| Item | Value |
|---|---|
| Base URL | `https://tablebuilder.singstat.gov.sg/api/table` |
| Endpoints | `/resourceid?keyword=…&searchOption=title`, `/tabledata/<table id>` |
| Headers | `User-Agent` identifying the project, `Accept: application/json` (requests without them were refused with 403) |
