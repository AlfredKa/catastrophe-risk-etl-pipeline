CREATE TABLE catastrophe (

    event_id TEXT PRIMARY KEY,
    event_time TIMESTAMP,
    magnitude NUMERIC,
    depth_km NUMERIC,
    latitude NUMERIC,
    longitude NUMERIC,
    place TEXT,
    risk_tier TEXT

);