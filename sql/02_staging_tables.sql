-- 02_staging_tables.sql  (execute in Retail_Staging)
IF SCHEMA_ID('stg') IS NULL EXEC('CREATE SCHEMA stg');
GO
CREATE TABLE IF NOT EXISTS stg.Customers_raw(
  CustomerID INT, FirstName VARCHAR(100), LastName VARCHAR(100),
  Email VARCHAR(200), Phone VARCHAR(50),
  City VARCHAR(100), StateProvince VARCHAR(100),
  CountryCode VARCHAR(10), PostalCode VARCHAR(20),
  LastModified DATETIME
);
CREATE TABLE IF NOT EXISTS stg.Products_raw(
  ProductID INT, ProductName VARCHAR(200),
  SubcategoryID INT, StandardCost DECIMAL(18,2),
  ListPrice DECIMAL(18,2), LastModified DATETIME
);
CREATE TABLE IF NOT EXISTS stg.ProductSubcategories_raw(
  SubcategoryID INT, SubcategoryName VARCHAR(200), CategoryID INT
);
CREATE TABLE IF NOT EXISTS stg.ProductCategories_raw(
  CategoryID INT, CategoryName VARCHAR(200)
);
CREATE TABLE IF NOT EXISTS stg.Promotions_raw(
  PromotionID INT, PromotionName VARCHAR(200),
  StartDate DATE, EndDate DATE, DiscountPct DECIMAL(5,2)
);
CREATE TABLE IF NOT EXISTS stg.Geographies_raw(
  GeographyID INT, City VARCHAR(100), StateProvince VARCHAR(100),
  CountryCode VARCHAR(10), CountryName VARCHAR(100), Region VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS stg.Sales_raw(
  SalesID BIGINT, OrderDate DATE, CustomerID INT, ProductID INT,
  PromotionID INT NULL, GeographyID INT, OrderQuantity INT,
  UnitPrice DECIMAL(18,2), DiscountAmount DECIMAL(18,2) NULL,
  CurrencyCode VARCHAR(10), LastModified DATETIME
);
