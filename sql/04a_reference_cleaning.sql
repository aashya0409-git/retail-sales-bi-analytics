-- 04a_reference_cleaning.sql
-- Purpose: Replace DQS with simple reference tables + views for standardized data.
-- Run this in the Retail_Staging database.

SET NOCOUNT ON;

IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO

-- 1) Reference tables
IF OBJECT_ID('stg.RefCountry','U') IS NULL
CREATE TABLE stg.RefCountry(
  CountryCode VARCHAR(10) NOT NULL PRIMARY KEY,
  CountryName VARCHAR(100) NOT NULL
);

IF OBJECT_ID('stg.RefState','U') IS NULL
CREATE TABLE stg.RefState(
  CountryCode VARCHAR(10) NOT NULL,
  StateStandard VARCHAR(100) NOT NULL,     -- canonical name (e.g., California)
  State2 VARCHAR(10) NULL,                 -- optional 2-letter code (e.g., CA)
  CONSTRAINT PK_RefState PRIMARY KEY (CountryCode, StateStandard)
);

IF OBJECT_ID('stg.RefCitySynonym','U') IS NULL
CREATE TABLE stg.RefCitySynonym(
  CountryCode VARCHAR(10) NOT NULL,
  StateStandard VARCHAR(100) NOT NULL,     -- canonical state
  CityVariant VARCHAR(100) NOT NULL,       -- messy/variant (e.g., New Yrok)
  CityStandard VARCHAR(100) NOT NULL,      -- canonical city (e.g., New York)
  CONSTRAINT PK_RefCitySynonym PRIMARY KEY (CountryCode, StateStandard, CityVariant)
);

-- 2) Seed minimal values (extend as needed)
MERGE stg.RefCountry AS tgt
USING (VALUES
  ('CA','Canada'),
  ('US','United States')
) AS src(CountryCode,CountryName)
ON (tgt.CountryCode=src.CountryCode)
WHEN NOT MATCHED BY TARGET THEN INSERT(CountryCode,CountryName) VALUES(src.CountryCode,src.CountryName);

MERGE stg.RefState AS tgt
USING (VALUES
  ('CA','Ontario','ON'),
  ('CA','British Columbia','BC'),
  ('US','New York','NY'),
  ('US','California','CA'),
  ('US','Washington','WA'),
  ('US','Florida','FL')
) AS src(CountryCode,StateStandard,State2)
ON (tgt.CountryCode=src.CountryCode AND tgt.StateStandard=src.StateStandard)
WHEN NOT MATCHED BY TARGET THEN
  INSERT(CountryCode,StateStandard,State2) VALUES(src.CountryCode,src.StateStandard,src.State2);

MERGE stg.RefCitySynonym AS tgt
USING (VALUES
  ('US','New York','New Yrok','New York'),
  ('US','California','Calif.','California'),  -- this is a state variant; handled below in state mapping
  ('US','California','Los Angeles','Los Angeles'), -- ensures match through canonical state
  ('US','Washington','Seattle','Seattle'),
  ('US','Florida','Miami','Miami'),
  ('CA','Ontario','Toronto','Toronto'),
  ('CA','Ontario','Mississauga','Mississauga'),
  ('CA','British Columbia','Vancouver','Vancouver'),
  ('CA','British Columbia','Surrey','Surrey')
) AS src(CountryCode,StateStandard,CityVariant,CityStandard)
ON (tgt.CountryCode=src.CountryCode AND tgt.StateStandard=src.StateStandard AND tgt.CityVariant=src.CityVariant)
WHEN NOT MATCHED BY TARGET THEN
  INSERT(CountryCode,StateStandard,CityVariant,CityStandard)
  VALUES(src.CountryCode,src.StateStandard,src.CityVariant,src.CityStandard);

-- 3) Normalization helpers: map messy state names to canonical (e.g., 'Calif.' -> 'California')
IF OBJECT_ID('stg.RefStateSynonym','U') IS NULL
CREATE TABLE stg.RefStateSynonym(
  CountryCode VARCHAR(10) NOT NULL,
  StateVariant VARCHAR(100) NOT NULL,      -- messy/variant (e.g., Calif.)
  StateStandard VARCHAR(100) NOT NULL,     -- canonical (e.g., California)
  CONSTRAINT PK_RefStateSynonym PRIMARY KEY (CountryCode, StateVariant)
);

MERGE stg.RefStateSynonym AS tgt
USING (VALUES
  ('US','Calif.','California')
) AS src(CountryCode,StateVariant,StateStandard)
ON (tgt.CountryCode=src.CountryCode AND tgt.StateVariant=src.StateVariant)
WHEN NOT MATCHED BY TARGET THEN
  INSERT(CountryCode,StateVariant,StateStandard)
  VALUES(src.CountryCode,src.StateVariant,src.StateStandard);

-- 4) Clean views
-- Geographies: standardize Country, State, City
-- Strategy:
--   a) Fix Country by code
--   b) Fix State by matching variant to standard (if present), else use given
--   c) Fix City by matching (Country, StateStandard) + City variant
-- Note: LEFT JOIN chain with COALESCE to keep original if not found in ref tables.

IF OBJECT_ID('stg.vw_Geographies_clean','V') IS NOT NULL
  DROP VIEW stg.vw_Geographies_clean;
GO
CREATE VIEW stg.vw_Geographies_clean AS
WITH base AS (
  SELECT
    g.GeographyID,
    g.City,
    g.StateProvince,
    g.CountryCode,
    g.CountryName,
    g.Region
  FROM stg.Geographies_raw g
),
state_norm AS (
  SELECT
    b.*,
    COALESCE(ss.StateStandard, b.StateProvince) AS StateStandard
  FROM base b
  LEFT JOIN stg.RefStateSynonym ss
    ON ss.CountryCode = b.CountryCode
   AND ss.StateVariant = b.StateProvince
),
country_norm AS (
  SELECT
    s.*,
    COALESCE(rc.CountryName, s.CountryName) AS CountryStandard
  FROM state_norm s
  LEFT JOIN stg.RefCountry rc
    ON rc.CountryCode = s.CountryCode
),
city_norm AS (
  SELECT
    c.*,
    COALESCE(cs.CityStandard, c.City) AS CityStandard
  FROM country_norm c
  LEFT JOIN stg.RefCitySynonym cs
    ON cs.CountryCode   = c.CountryCode
   AND cs.StateStandard = c.StateStandard
   AND cs.CityVariant   = c.City
)
SELECT
  GeographyID,
  CityStandard     AS City_Clean,
  StateStandard    AS StateProvince_Clean,
  CountryCode      AS CountryCode_Clean,
  CountryStandard  AS CountryName_Clean,
  Region
FROM city_norm;

-- Customers clean view: reuse the same logic by joining to the geography mapping using best-effort matches
IF OBJECT_ID('stg.vw_Customers_clean','V') IS NOT NULL
  DROP VIEW stg.vw_Customers_clean;
GO
CREATE VIEW stg.vw_Customers_clean AS
WITH c AS (
  SELECT * FROM stg.Customers_raw
),
state_norm AS (
  SELECT
    c.*,
    COALESCE(ss.StateStandard, c.StateProvince) AS StateStandard
  FROM c
  LEFT JOIN stg.RefStateSynonym ss
    ON ss.CountryCode = c.CountryCode
   AND ss.StateVariant = c.StateProvince
),
country_norm AS (
  SELECT
    s.*,
    COALESCE(rc.CountryName, s.CountryName) AS CountryStandard
  FROM state_norm s
  LEFT JOIN stg.RefCountry rc
    ON rc.CountryCode = s.CountryCode
),
city_norm AS (
  SELECT
    cn.*,
    COALESCE(cs.CityStandard, cn.City) AS CityStandard
  FROM country_norm cn
  LEFT JOIN stg.RefCitySynonym cs
    ON cs.CountryCode   = cn.CountryCode
   AND cs.StateStandard = cn.StateStandard
   AND cs.CityVariant   = cn.City
)
SELECT
  CustomerID, FirstName, LastName, Email, Phone,
  CityStandard        AS City_Clean,
  StateStandard       AS StateProvince_Clean,
  CountryCode         AS CountryCode_Clean,
  CountryStandard     AS CountryName_Clean,
  PostalCode, LastModified
FROM city_norm;
