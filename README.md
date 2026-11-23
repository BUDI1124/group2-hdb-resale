# What drives HDB resale prices?

Generation JDEA – Interim Project (RR-P1) · **Group 2**

A Python pipeline that retrieves HDB resale transactions from public REST APIs, cleans and analyses them in Pandas, and feeds an interactive Power BI report.

## Business questions
| # | Question |
|---|---|
| Q1 | Which towns have the fastest resale price growth since 2017? |
| Q2 | How much does remaining lease affect price per sqm? |
| Q3 | What premium do buyers pay for higher floors? |
| Q4 | Which flat types and models hold their value best? |
| Q5 | How do our transactions compare with HDB's official Resale Price Index? |

## Data sources (REST APIs)
| Source | Dataset ID | Auth | Role |
|---|---|---|---|
| data.gov.sg – Resale flat prices from Jan 2017 | `d_8b84c4ee58e3cfc0ece0d773c8ca6abc` | API key (from `.env`) | Main fact table |
| data.gov.sg – HDB Resale Price Index (1Q2009 = 100), quarterly | `d_14f63e595975691e7c24a27ae4c07c79` | API key (from `.env`) | Benchmark, merged by quarter |
| SingStat Table Builder (optional) | CPI / household income | none | Inflation-adjusted prices |

Endpoint details, headers, parameters and response schema: [`docs/api_endpoints.md`](docs/api_endpoints.md).
Licence: Singapore Open Data Licence. Source: Housing & Development Board via data.gov.sg.

## Folder structure
```
src/            api_client.py – reusable requests client (Task 1)
notebooks/      00_get_data → 01_inspect → 02_clean → 03_analysis
data/raw/       raw API responses (JSON/CSV) – not committed, recreate with 00_get_data
data/clean/     output of 02_clean – not committed
reports/        Power BI .pbix, PDF export, slides
docs/           API docs, data dictionary, sprint notes, backlog script
```

## How to run
1. Activate your conda environment and run `pip install -r requirements.txt`
2. Copy `.env.example` to `.env` and paste **your own** data.gov.sg API key. Never commit `.env`.
3. Run the notebooks in order with **Restart & Run All**.

## Team (Scrum roles)
| Role | Name | GitHub |
|---|---|---|
| Product Owner | | |
| Scrum Master | | |
| Data Engineer | | |
| Data Analyst | | |
| BI Lead | | |

## Ways of working
- Backlog and sprints: GitHub Projects board **Group 2 Sprint Board**; sprints are GitHub milestones
- One branch per issue: `feature/<issue-no>-short-name`
- Pull request reviewed by a teammate; write `closes #<issue-no>` in the PR
- **Definition of Done:** acceptance criteria ticked · notebook runs top to bottom · header comment (Purpose / Input / Output) · no secrets · results checked · PR reviewed and merged · card moved to Done

| Sprint | Dates (proposed) | Goal |
|---|---|---|
| Sprint 1 – Ingest | 25–30 Nov 2026 | Raw data retrieved through an authenticated, reusable API client |
| Sprint 2 – Clean & analyse | 1–6 Dec 2026 | One validated dataset and answers to Q1–Q5 |
| Sprint 3 – Report | 7–13 Dec 2026 | Power BI report, checklist, slides |
| Interim presentation | 14 Dec 2026 | |
