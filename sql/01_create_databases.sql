-- 01_create_databases.sql
IF DB_ID('Retail_Staging') IS NULL CREATE DATABASE Retail_Staging;
IF DB_ID('Retail_DW') IS NULL CREATE DATABASE Retail_DW;
GO
