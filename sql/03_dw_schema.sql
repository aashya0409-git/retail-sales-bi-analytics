-- 03_dw_schema.sql  (execute in Retail_DW)
CREATE TABLE IF NOT EXISTS dbo.DimCustomer(
  CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
  CustomerID INT NOT NULL,
  FirstName NVARCHAR(100), LastName NVARCHAR(100),
  Email NVARCHAR(200), Phone NVARCHAR(50),
  City NVARCHAR(100), StateProvince NVARCHAR(100),
  CountryCode NVARCHAR(10), PostalCode NVARCHAR(20),
  StartDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
  EndDate   DATETIME2 NULL,
  IsCurrent BIT NOT NULL DEFAULT 1,
  HashDiff  VARBINARY(32) NULL
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UX_DimCustomer_BK_Current')
  CREATE UNIQUE INDEX UX_DimCustomer_BK_Current ON dbo.DimCustomer(CustomerID, IsCurrent) WHERE IsCurrent=1;

CREATE TABLE IF NOT EXISTS dbo.DimProduct(
  ProductKey INT IDENTITY(1,1) PRIMARY KEY,
  ProductID INT NOT NULL UNIQUE,
  ProductName NVARCHAR(200),
  Subcategory NVARCHAR(200),
  Category NVARCHAR(200),
  StandardCost DECIMAL(18,2),
  ListPrice DECIMAL(18,2),
  LastModified DATETIME2
);

CREATE TABLE IF NOT EXISTS dbo.DimGeography(
  GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
  GeographyID INT NOT NULL UNIQUE,
  OriginalCity NVARCHAR(100),
  CurrentCity NVARCHAR(100),
  StateProvince NVARCHAR(100),
  CountryCode NVARCHAR(10),
  CountryName NVARCHAR(100),
  Region NVARCHAR(100),
  EffectiveDate DATETIME2
);

CREATE TABLE IF NOT EXISTS dbo.DimPromotion(
  PromotionKey INT IDENTITY(1,1) PRIMARY KEY,
  PromotionID INT NOT NULL UNIQUE,
  PromotionName NVARCHAR(200),
  StartDate DATE, EndDate DATE, DiscountPct DECIMAL(5,2)
);

CREATE TABLE IF NOT EXISTS dbo.DimDate(
  DateKey INT PRIMARY KEY,
  FullDate DATE,
  CalendarYear INT, CalendarQuarter INT,
  MonthNumber INT, MonthName NVARCHAR(20),
  DayNumber INT, DayName NVARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dbo.FactInternetSales(
  SalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
  DateKey INT NOT NULL,
  CustomerKey INT NOT NULL,
  ProductKey INT NOT NULL,
  PromotionKey INT NULL,
  GeographyKey INT NOT NULL,
  OrderQuantity INT,
  UnitPrice DECIMAL(18,2),
  DiscountAmount DECIMAL(18,2),
  SalesAmount AS (OrderQuantity * UnitPrice - ISNULL(DiscountAmount,0)) PERSISTED,
  CurrencyCode NVARCHAR(10),
  FOREIGN KEY(DateKey) REFERENCES dbo.DimDate(DateKey),
  FOREIGN KEY(CustomerKey) REFERENCES dbo.DimCustomer(CustomerKey),
  FOREIGN KEY(ProductKey) REFERENCES dbo.DimProduct(ProductKey),
  FOREIGN KEY(PromotionKey) REFERENCES dbo.DimPromotion(PromotionKey),
  FOREIGN KEY(GeographyKey) REFERENCES dbo.DimGeography(GeographyKey)
);
