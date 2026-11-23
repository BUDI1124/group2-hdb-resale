# =====================================================================
# Purpose: Set up the Group 2 HDB repo backlog:
#          1) create labels and 3 sprint milestones
#          2) create the 18 HDB user stories from the project charter
#          3) add them to the project board (optional, -ProjectNumber)
# Input:   -Repo OWNER/REPO (e.g. BUDI1124/group2-hdb-resale)
#          -ProjectNumber   board number from: gh project list --owner BUDI1124
#          Requires gh logged in (gh auth status); board step needs: gh auth refresh -s project
# Output:  labels, milestones "Sprint 1/2/3", 18 issues, optional board items
# Run in:  PowerShell, inside your conda env:
#          Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#          .\docs\setup_hdb_backlog.ps1 -Repo BUDI1124/group2-hdb-resale -ProjectNumber 2
# NOTE:    Run ONCE. Running again creates duplicate issues.
# =====================================================================
param(
    [Parameter(Mandatory = $true)][string]$Repo,
    [int]$ProjectNumber = 0
)
$Owner = $Repo.Split('/')[0]

# --- 1. Labels (--force updates them if they already exist) ---
gh label create setup    --repo $Repo --color 5319E7 --description 'Repo and team set-up' --force
gh label create api      --repo $Repo --color 0E8A16 --description 'Task 1: API integration' --force
gh label create clean    --repo $Repo --color 1D76DB --description 'Task 2: cleaning and transformation' --force
gh label create analyse  --repo $Repo --color FBCA04 --description 'Task 2: statistics and charts' --force
gh label create report   --repo $Repo --color D93F0B --description 'Task 3: Power BI and presentation' --force

# --- 2. Sprint milestones (an error here just means it already exists) ---
$S1 = 'Sprint 1 - Ingest'
$S2 = 'Sprint 2 - Clean and analyse'
$S3 = 'Sprint 3 - Report'
gh api "repos/$Repo/milestones" -f title=$S1 -f due_on='2026-11-30T15:59:59Z' -f description='Raw data retrieved through an authenticated, reusable API client' | Out-Null
gh api "repos/$Repo/milestones" -f title=$S2 -f due_on='2026-12-06T15:59:59Z' -f description='One validated dataset and answers to Q1-Q5' | Out-Null
gh api "repos/$Repo/milestones" -f title=$S3 -f due_on='2026-12-13T15:59:59Z' -f description='Power BI report, checklist and slides for 14 Dec' | Out-Null

# --- Helper: one user story = one issue ---
$created = @()
function New-Story([string]$Title, [string]$Labels, [int]$Points, [string]$Role, [string]$Milestone, [string]$Story, [string[]]$Criteria) {
    $checks = ($Criteria | ForEach-Object { "- [ ] $_" }) -join "`n"
    $body = "**User story**`n$Story`n`n**Story points:** $Points`n**Role:** $Role`n`n**Acceptance criteria**`n$checks"
    $url = gh issue create --repo $Repo --title $Title --label $Labels --milestone $Milestone --body $body
    if ($LASTEXITCODE -ne 0) { throw "Failed to create issue: $Title" }   # stop on error
    Write-Host $url
    $script:created += $url
}

# --- 3. HDB product backlog (order = priority) ---
# Sprint 1 - Ingest (14 points)
New-Story 'Set up repo structure, README and .env template' 'setup' 1 'Data Engineer' $S1 `
  'As a team, we want a repo structure, README and .env template so that everyone works the same way.' `
  @('Folders src, notebooks, data/raw, data/clean, reports, docs exist', 'README updated with topic, team and how to run', '.env.example added and .env is in .gitignore')
New-Story 'Agree business questions and Definition of Done' 'setup' 1 'Product Owner' $S1 `
  'As the Product Owner, I want the business questions and Definition of Done agreed so that the work has a clear target.' `
  @('Q1-Q5 confirmed by the team and written in README', 'Definition of Done agreed and in README', 'Charter signed off by all members')
New-Story 'Build reusable API client (src/api_client.py)' 'api' 5 'Data Engineer' $S1 `
  'As a data engineer, I want a reusable api_client.py with API-key headers, paging, retries and timeouts so that every call is reliable.' `
  @('Uses requests with a Session, timeout and retry on 429/5xx', 'API key read from .env, never hard-coded', 'Pages through limit/offset until all records are returned', 'Header comment and docstrings (Purpose / Input / Output)')
New-Story 'Retrieve all resale transactions (Jan 2017 onwards)' 'api' 3 'Data Engineer' $S1 `
  'As a data engineer, I want all resale transactions retrieved and saved as raw JSON/CSV so that results are reproducible.' `
  @('Raw JSON pages saved in data/raw', 'Combined raw CSV saved in data/raw', 'Row count and date range printed and logged in docs/api_endpoints.md')
New-Story 'Retrieve HDB Resale Price Index (quarterly)' 'api' 2 'Data Engineer' $S1 `
  'As an analyst, I want the Resale Price Index retrieved and saved so that we can benchmark our data.' `
  @('Raw JSON and CSV saved in data/raw', 'Quarters and index values checked')
New-Story 'Document endpoints, headers, parameters and response schema' 'api' 2 'Scrum Master' $S1 `
  'As an assessor, I want base URLs, headers, parameters and the response schema documented so that the API work can be checked.' `
  @('docs/api_endpoints.md completed for every endpoint', 'Schema printed in 00_get_data and copied into the doc')

# Sprint 2 - Clean and analyse (18 points)
New-Story 'Validate field types and value ranges' 'clean' 2 'Data Engineer' $S2 `
  'As an analyst, I want types and value ranges validated so that bad records are found early.' `
  @('Numeric fields converted with errors flagged', 'Range checks: price > 0, floor area 20-300 sqm, lease year plausible', 'Failed rows flagged, counted and explained')
New-Story 'Handle missing values and duplicates with rationale' 'clean' 2 'Data Engineer' $S2 `
  'As an analyst, I want missing values and duplicates handled with a written rationale so that decisions are traceable.' `
  @('Missing values counted per column, decision written for each', 'Duplicates flagged or removed, count reported')
New-Story 'Standardise dates (ISO 8601) and normalise strings' 'clean' 3 'Data Engineer' $S2 `
  'As an analyst, I want ISO dates and normalised strings so that fields can be grouped and calculated.' `
  @('month converted to YYYY-MM-DD', 'Town, flat type and model: stripped and consistent casing', 'remaining_lease "61 years 04 months" parsed to years (float)', 'storey_range parsed to low / high / mid floor')
New-Story 'Create derived metrics (price/sqm, YoY growth, rolling median, rank)' 'clean' 3 'Data Analyst' $S2 `
  'As an analyst, I want derived metrics so that the business questions can be answered.' `
  @('price_per_sqm, lease band, storey band columns', 'YoY % growth and 12-month rolling median by town', 'Town rank by growth')
New-Story 'Merge transactions with Resale Price Index by quarter' 'clean' 2 'Data Analyst' $S2 `
  'As an analyst, I want transactions merged with the price index by quarter so that Q5 can be answered.' `
  @('Quarter key built on both tables', 'Merge checked: no lost rows, unmatched quarters reported')
New-Story 'Descriptive statistics and charts for Q1-Q5' 'analyse' 5 'Data Analyst' $S2 `
  'As a home buyer, I want statistics and charts for Q1-Q5 so that I see what drives prices.' `
  @('describe() for key metrics', 'At least one chart per question saved to reports/figures', 'One-sentence insight per question')
New-Story 'Write data dictionary' 'analyse' 1 'Data Engineer' $S2 `
  'As a reviewer, I want a data dictionary so that every column is explained.' `
  @('docs/data_dictionary.md lists every raw and derived column with type and meaning')

# Sprint 3 - Report (14 points)
New-Story 'Power BI data model with Date table and relationships' 'report' 2 'BI Lead' $S3 `
  'As a report user, I want a data model with a Date table and relationships so that filters work across pages.' `
  @('Clean CSVs imported with correct types', 'Date table marked, relationships set')
New-Story 'DAX measures (median price/sqm, YoY %, count, rank)' 'report' 3 'BI Lead' $S3 `
  'As a report user, I want consistent DAX measures so that numbers match across visuals.' `
  @('Measures in a _Measures table with formats', 'Each measure tested against a known value')
New-Story 'Report pages, slicers and town drill-through' 'report' 5 'BI Lead' $S3 `
  'As a report user, I want 4 report pages with slicers and a town drill-through so that I can explore the data.' `
  @('4 pages with consistent layout', 'Slicers: town, flat type, year, lease band', 'Drill-through page by town works')
New-Story 'Check Power BI totals against Python' 'report' 1 'Scrum Master' $S3 `
  'As the Product Owner, I want report totals checked against Python so that the dashboard is trustworthy.' `
  @('Transaction count and median price match notebook 03')
New-Story 'Findings, Deliverables Checklist and presentation slides' 'report' 3 'Whole team' $S3 `
  'As a team, we want findings, the checklist and slides ready so that we can present on 14 Dec.' `
  @('3-5 recommendations linked to findings', 'Deliverables Checklist filled in', 'Slides with speaker notes; every member presents a section')

# --- 4. Add the new issues to the project board (optional) ---
if ($ProjectNumber -gt 0) {
    foreach ($u in $created) {
        gh project item-add $ProjectNumber --owner $Owner --url $u | Out-Null
    }
    Write-Host "Added $($created.Count) issues to project $ProjectNumber"
}
Write-Host "Done: $($created.Count) HDB stories created."
