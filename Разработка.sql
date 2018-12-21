
DECLARE @Database               nvarchar(255);
DECLARE @SourceTable            nvarchar(255);
DECLARE @DestinationTable       nvarchar(255);
DECLARE @PartionField           nvarchar(255);
DECLARE @SourceSchema           nvarchar(255) = 'dbo'; 
DECLARE @DestinationSchema      nvarchar(255) = 'dbo';   
DECLARE  @RecreateIfExists       bit = 1;


SET @SourceTable = '_Document180';
SET @DestinationTable = '_Document180_NEW';


DECLARE @msg  nvarchar(200), @PartionScript nvarchar(255), @sql NVARCHAR(MAX)

    IF EXISTS(Select s.name As SchemaName, t.name As TableName
                        From sys.tables t
                        Inner Join sys.schemas s On t.schema_id = s.schema_id
                        Inner Join sys.partitions p on p.object_id = t.object_id
                        Where p.index_id In (0, 1) and t.name = @SourceTable
                        Group By s.name, t.name
                        Having Count(*) > 1)

        SET @PartionScript = ' ON [PS_PartitionByCompanyId]([' + @PartionField + '])'
    else
        SET @PartionScript = ''

SET NOCOUNT ON;
BEGIN TRY   
    SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 1, Drop table if exists. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
     RAISERROR( @msg,0,1) WITH NOWAIT
    --drop the table
    if EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @DestinationTable)
    BEGIN
        if @RecreateIfExists = 1
            BEGIN
                exec('DROP TABLE [' + @DestinationSchema + '].[' + @DestinationTable + ']')
            END
        ELSE
            RETURN
    END

    SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 2, Create table. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
    RAISERROR( @msg,0,1) WITH NOWAIT
    --create the table
    exec('SELECT TOP (0) * INTO [' + @DestinationTable + '] FROM [' + @SourceTable + ']')       

    --create primary key
    SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 3, Create primary key. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
    RAISERROR( @msg,0,1) WITH NOWAIT
    DECLARE @PKSchema nvarchar(255), @PKName nvarchar(255),@count   INT
    SELECT TOP 1 @PKSchema = CONSTRAINT_SCHEMA, @PKName = CONSTRAINT_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = @SourceSchema AND TABLE_NAME = @SourceTable AND CONSTRAINT_TYPE = 'PRIMARY KEY'
    IF NOT @PKSchema IS NULL AND NOT @PKName IS NULL
    BEGIN
        DECLARE @PKColumns nvarchar(MAX)
        SET @PKColumns = ''

        SELECT @PKColumns = @PKColumns + '[' + COLUMN_NAME + '],'
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
            where TABLE_NAME = @SourceTable and TABLE_SCHEMA = @SourceSchema AND CONSTRAINT_SCHEMA = @PKSchema AND CONSTRAINT_NAME= @PKName
            ORDER BY ORDINAL_POSITION

        SET @PKColumns = LEFT(@PKColumns, LEN(@PKColumns) - 1)

        exec('ALTER TABLE [' + @DestinationSchema + '].[' + @DestinationTable + '] ADD  CONSTRAINT [PK_' + @DestinationTable + '] PRIMARY KEY CLUSTERED (' + @PKColumns + ')' + @PartionScript);
    END

    --create other indexes
    SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 4, Create Indexes. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
    RAISERROR( @msg,0,1) WITH NOWAIT
    DECLARE @IndexId int, @IndexName nvarchar(255), @IsUnique bit, @IsUniqueConstraint bit, @FilterDefinition nvarchar(max), @type int

    set @count=0
    DECLARE indexcursor CURSOR FOR
    SELECT index_id, name, is_unique, is_unique_constraint, filter_definition, type FROM sys.indexes WHERE is_primary_key = 0 and object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']')
    OPEN indexcursor;
    FETCH NEXT FROM indexcursor INTO @IndexId, @IndexName, @IsUnique, @IsUniqueConstraint, @FilterDefinition, @type
    WHILE @@FETCH_STATUS = 0
       BEGIN
            set @count =@count +1
            DECLARE @Unique nvarchar(255)
            SET @Unique = CASE WHEN @IsUnique = 1 THEN ' UNIQUE ' ELSE '' END

            DECLARE @KeyColumns nvarchar(max), @IncludedColumns nvarchar(max)
            SET @KeyColumns = ''
            SET @IncludedColumns = ''

            select @KeyColumns = @KeyColumns + '[' + c.name + '] ' + CASE WHEN is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END + ',' from sys.index_columns ic
            inner join sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
            where index_id = @IndexId and ic.object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']') and key_ordinal > 0
            order by index_column_id

            select @IncludedColumns = @IncludedColumns + '[' + c.name + '],' from sys.index_columns ic
            inner join sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
            where index_id = @IndexId and ic.object_id = object_id('[' + @SourceSchema + '].[' + @SourceTable + ']') and key_ordinal = 0
            order by index_column_id

            IF LEN(@KeyColumns) > 0
                SET @KeyColumns = LEFT(@KeyColumns, LEN(@KeyColumns) - 1)

            IF LEN(@IncludedColumns) > 0
            BEGIN
                SET @IncludedColumns = ' INCLUDE (' + LEFT(@IncludedColumns, LEN(@IncludedColumns) - 1) + ')'
            END

            IF @FilterDefinition IS NULL
                SET @FilterDefinition = ''
            ELSE
                SET @FilterDefinition = 'WHERE ' + @FilterDefinition + ' '

            SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 4.' + CONVERT(NVARCHAR(5),@count) + ', Create Index ' + @IndexName + '. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
            RAISERROR( @msg,0,1) WITH NOWAIT

            if @type = 2
                SET @sql = 'CREATE ' + @Unique + ' NONCLUSTERED INDEX [' + @IndexName + '] ON [' + @DestinationSchema + '].[' + @DestinationTable + '] (' + @KeyColumns + ')' + @IncludedColumns + @FilterDefinition  + @PartionScript
            ELSE
                BEGIN
                    SET @sql = 'CREATE ' + @Unique + ' CLUSTERED INDEX [' + @IndexName + '] ON [' + @DestinationSchema + '].[' + @DestinationTable + '] (' + @KeyColumns + ')' + @IncludedColumns + @FilterDefinition + @PartionScript
                END
            EXEC (@sql)
            FETCH NEXT FROM indexcursor INTO @IndexId, @IndexName, @IsUnique, @IsUniqueConstraint, @FilterDefinition, @type
       END
    CLOSE indexcursor
    DEALLOCATE indexcursor

    --create constraints
    SET @msg ='  CloneTable  ' + @DestinationTable + ' - Step 5, Create constraints. Timestamp: '  + CONVERT(NVARCHAR(50),GETDATE(),108)
    RAISERROR( @msg,0,1) WITH NOWAIT
    DECLARE @ConstraintName nvarchar(max), @CheckClause nvarchar(max), @ColumnName NVARCHAR(255)
    DECLARE const_cursor CURSOR FOR
        SELECT
            REPLACE(dc.name, @SourceTable, @DestinationTable),[definition], c.name
        FROM sys.default_constraints dc
            INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE OBJECT_NAME(parent_object_id) =@SourceTable               
    OPEN const_cursor
    FETCH NEXT FROM const_cursor INTO @ConstraintName, @CheckClause, @ColumnName
    WHILE @@FETCH_STATUS = 0
       BEGIN
            exec('ALTER TABLE [' + @DestinationTable + '] ADD CONSTRAINT [' + @ConstraintName + '] DEFAULT ' + @CheckClause + ' FOR ' + @ColumnName)
            FETCH NEXT FROM const_cursor INTO @ConstraintName, @CheckClause, @ColumnName
       END;
    CLOSE const_cursor
    DEALLOCATE const_cursor                 


END TRY
    BEGIN CATCH
        IF (SELECT CURSOR_STATUS('global','indexcursor')) >= -1
        BEGIN
         DEALLOCATE indexcursor
        END

        IF (SELECT CURSOR_STATUS('global','const_cursor')) >= -1
        BEGIN
         DEALLOCATE const_cursor
        END


        PRINT 'Error Message: ' + ERROR_MESSAGE(); 
    END CATCH

