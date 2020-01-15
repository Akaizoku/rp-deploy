USE [master]
GO
ALTER DATABASE [${sqlserver.db}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
USE [master]
GO
drop login [${sqlserver.user}]
