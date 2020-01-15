CREATE DATABASE [${sqlserver.db}]
COLLATE ${sqlserver.collation}
GO
ALTER DATABASE [${sqlserver.db}] MODIFY FILE ( name = N'${sqlserver.db}', filegrowth = 128MB, size = 1GB )
GO
ALTER DATABASE [${sqlserver.db}] MODIFY FILE ( name = N'${sqlserver.db}_log', size = 512MB )
GO
