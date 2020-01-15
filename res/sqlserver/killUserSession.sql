DECLARE @statement nvarchar(2000)
SELECT @statement = @statement + 'kill ' + CONVERT(varchar(5), spid)
FROM master..sysprocesses
WHERE dbid = db_id('${sqlserver.db}')
EXEC sp_executesql @statement
GO
