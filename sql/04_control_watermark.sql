-- 04_control_watermark.sql  (execute in Retail_DW)
IF OBJECT_ID('dbo.ETL_Control') IS NULL
CREATE TABLE dbo.ETL_Control(
  ProcessName NVARCHAR(100) PRIMARY KEY,
  LastWatermark DATETIME2 NULL
);
IF NOT EXISTS (SELECT 1 FROM dbo.ETL_Control WHERE ProcessName='SalesFact')
INSERT dbo.ETL_Control(ProcessName, LastWatermark) VALUES('SalesFact', NULL);
