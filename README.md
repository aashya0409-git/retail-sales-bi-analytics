# Retail Sales Data Warehouse & BI (MSBI Stack)

**Stack:** SQL Server, SSIS (ETL), DQS (Data Quality), SSAS (OLAP Cube), SSRS (Reports)

## How to Run (Quick Start)
1. Open SQL Server Management Studio (SSMS).
2. Run `sql/01_create_databases.sql` on `master`.
3. Switch to `Retail_Staging` and run `sql/02_staging_tables.sql` to create staging tables.
4. Switch to `Retail_DW` and run `sql/03_dw_schema.sql` to create DW tables.
5. Run `sql/03a_seed_dimdate.sql` to populate `DimDate`.
6. Load CSVs from `data/raw/` into `stg.*_raw` using SSIS (Project coming soon).
7. (Optional) Run `sql/04_control_watermark.sql` for incremental loads control table.
8. Build SSAS cube and SSRS reports (see docs).

## Data
- CSV samples in `data/raw/`. Includes minor data-quality issues to demonstrate DQS.

## Docs
- Add screenshots of SSIS packages, DQS results, SSAS cube explorer, and SSRS reports to `docs/screenshots/`.
- Architecture diagrams in `docs/architecture/`.


## DQS-free Cleaning (Beginner Friendly)
Run `sql/04a_reference_cleaning.sql` in `Retail_Staging` to create small reference tables and
two clean views:
- `stg.vw_Geographies_clean`
- `stg.vw_Customers_clean`

Then point your SSIS dimension loads at these views instead of the raw tables.
Extend the `Ref*` tables with more synonyms as you find new variations.
