USE [master];

-- Define variables
DECLARE @schema	        NVARCHAR(255)
DECLARE @drop_database	NVARCHAR(255)
DECLARE @drop_user		  NVARCHAR(255)

-- Set values
SET @schema         = N'#{Schema}'
SET @drop_database	= N'DROP DATABASE IF EXISTS '   + @schema
SET @drop_user		  = N'DROP LOGIN '                + @schema

-- Drop database
EXEC master.sys.sp_executesql @drop_database;

-- Drop user/login
IF EXISTS (SELECT NULL from master.sys.syslogins WHERE name = @schema)
EXEC master.sys.sp_executesql @drop_user;
