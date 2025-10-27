-- 04_staging_hashdiff.sql  (execute in Retail_Staging)
CREATE OR ALTER VIEW stg.vw_Customers_hash AS
SELECT
  c.*,
  HASHBYTES('SHA2_256',
        CONCAT(ISNULL(FirstName,''),'|',ISNULL(LastName,''),'|',ISNULL(Email,''),'|',
               ISNULL(Phone,''),'|',ISNULL(City,''),'|',ISNULL(StateProvince,''),'|',
               ISNULL(CountryCode,''),'|',ISNULL(PostalCode,''))) AS HashDiff
FROM stg.Customers_raw c;
