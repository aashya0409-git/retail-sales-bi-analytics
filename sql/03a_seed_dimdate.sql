-- 03a_seed_dimdate.sql  (execute in Retail_DW)
SET NOCOUNT ON;
DECLARE @StartDate DATE='2018-01-01', @EndDate DATE='2027-12-31';
WITH N AS (
  SELECT @StartDate AS d
  UNION ALL SELECT DATEADD(DAY,1,d) FROM N WHERE d < @EndDate
)
INSERT INTO dbo.DimDate(DateKey, FullDate, CalendarYear, CalendarQuarter, MonthNumber, MonthName, DayNumber, DayName)
SELECT
  CONVERT(INT, FORMAT(d, 'yyyyMMdd')),
  d,
  YEAR(d),
  DATEPART(QUARTER,d),
  MONTH(d),
  DATENAME(MONTH,d),
  DAY(d),
  DATENAME(WEEKDAY,d)
FROM N
WHERE NOT EXISTS (SELECT 1 FROM dbo.DimDate x WHERE x.FullDate = N.d)
OPTION (MAXRECURSION 0);
