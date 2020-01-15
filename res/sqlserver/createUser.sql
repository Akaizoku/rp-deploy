CREATE LOGIN [${sqlserver.user}] WITH
  password=N'${sqlserver.password}',
  default_database=[${sqlserver.db}],
  default_language=[us_english],
  check_expiration=off,
  check_policy=off
GO
USE [${sqlserver.db}]
GO
CREATE USER [${sqlserver.user}] FOR LOGIN [${sqlserver.user}]
GO
ALTER USER [${sqlserver.user}] WITH default_schema=[${sqlserver.schema}]
GO
EXEC sp_addrolemember N'db_owner', N'${sqlserver.user}'
GO
