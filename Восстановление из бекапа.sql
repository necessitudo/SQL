
RESTORE DATABASE [dubrovinom_plazma] FROM  DISK = N'D:\ֵנרמג\backups\LastCopyPlazma.bak' WITH  FILE = 1,  MOVE N'Plazma' TO N'M:\mssqldata\dubrovinom_plazma.mdf',  MOVE N'Plazma_log' TO N'M:\mssqldata\dubrovinom_plazma_1.LDF',  NOUNLOAD,  REPLACE,  STATS = 5

GO

ALTER DATABASE [dubrovinom_plazma] SET RECOVERY SIMPLE ;
GO


RESTORE DATABASE [DubrovinPlazma] FROM  DISK = N'D:\ֵנרמג\backups\LastCopyPlazma.bak' WITH  FILE = 1,  MOVE N'Plazma' TO N'D:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\DubrovinPlazma.mdf',  MOVE N'Plazma_log' TO N'D:\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data\DubrovinPlazma_1.LDF',  NOUNLOAD,  REPLACE,  STATS = 5

GO

ALTER DATABASE [DubrovinPlazma] SET RECOVERY SIMPLE ;
GO

