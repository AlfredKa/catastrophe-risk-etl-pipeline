# Catastrophe Risk ETL Pipeline

An end-to-end ETL (Extract, Transform, Load) pipeline that ingests global
earthquake data from the USGS Earthquake API, transforms it into a clean,
structured format, and loads it into a PostgreSQL database — framed around
catastrophe/seismic risk, a real factor in property and reinsurance
underwriting.

## What This Project Demonstrates

- Pulling live data from a public REST API (no auth required)
- Parsing nested GeoJSON into a flat, analysis-ready format
- Handling real-world data quirks (Unix millisecond timestamps, nested
  coordinate arrays)
- Deriving a business-relevant field (risk tier) from raw data
- Designing a database schema before writing any pipeline code
- Loading data safely into PostgreSQL with credentials kept out of
  version control
- Handling idempotency — safely re-running the pipeline without creating
  duplicate records

## Data Source

[USGS Earthquake API](https://earthquake.usgs.gov/fdsnws/event/1/) — a
free, public, no-authentication GeoJSON feed maintained by the US
Geological Survey. This project pulls global earthquakes of magnitude
4.5+ over a rolling 30-day window.

## Pipeline Overview

**1. Extract**
A request is made to the USGS query endpoint with parameters for date
range and minimum magnitude, returning a GeoJSON response containing a
list of earthquake "features."

**2. Transform**
Each feature is parsed to extract: event ID, magnitude, place
description, event time (converted from a Unix millisecond timestamp to
a proper datetime), and longitude/latitude/depth from the nested
geometry object. A `risk_tier` column is then derived from magnitude:

| Magnitude | Risk Tier |
|---|---|
| Below 5.0 | Low |
| 5.0 – 6.0 | Moderate |
| Above 6.0 | High |

**3. Load**
The cleaned data is loaded into a PostgreSQL table (`catastrophe`) with
`event_id` as the primary key. Before each load, the pipeline checks
which `event_id`s already exist in the table and only inserts new
records — making it safe to re-run without duplicate-key errors.

## Database Schema

| Column | Type | Notes |
|---|---|---|
| `event_id` | TEXT | Primary key, unique USGS event identifier |
| `event_time` | TIMESTAMP | When the earthquake occurred |
| `magnitude` | NUMERIC | Earthquake magnitude |
| `depth_km` | NUMERIC | Depth of the event in kilometers |
| `latitude` | NUMERIC | |
| `longitude` | NUMERIC | |
| `place` | TEXT | Human-readable location |
| `risk_tier` | TEXT | Derived: Low / Moderate / High, based on magnitude |

## Findings

Over the sampled 30-day window (582 events, magnitude 4.5+):

- **446 events (77%)** fell into the **Low** risk tier, **128 (22%)**
  were **Moderate**, and only **8 (1%)** were **High**-magnitude —
  consistent with the real-world pattern that large, damaging
  earthquakes are far rarer than smaller ones.
- Depth varied widely: from as shallow as 3.2km to as deep as 676.5km,
  with a median depth of just 11.6km. The wide gap between the median
  and mean (~60km) shows depth is heavily right-skewed — most
  earthquakes are shallow, with a smaller number of much deeper events
  pulling the average up. This matters for risk modeling, since shallow
  earthquakes generally cause more surface damage at the same magnitude.

## Tools

Python, pandas, `requests`, SQLAlchemy, `psycopg2`, PostgreSQL,
`python-dotenv`

## How to Run

1. Clone this repo
2. `pip install pandas requests sqlalchemy psycopg2-binary python-dotenv`
3. Create a PostgreSQL database and run the schema in `schema.sql`
   (or the `CREATE TABLE` statement documented above)
4. Create a `.env` file in the repo root with:
   ```
   DB_PASSWORD=your_postgres_password
   ```
5. Open `notebooks/` and run the pipeline notebook — it will extract,
   transform, and load new earthquake data, skipping any records
   already in the database