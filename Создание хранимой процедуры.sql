
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  croppingDatabaseAccordingToSettings

	@database NVARCHAR(100)

AS
BEGIN
	
	SET ANSI_NULLS ON

	SET QUOTED_IDENTIFIER ON

	SET NOCOUNT ON;

	
	SET @database = '[dubrovinom_plazma]';

	DECLARE @sqlstatement NVARCHAR(MAX);

	DECLARE @debug BIT = 0;

	/*
	1) �������� ������ �� ������� [���������������������������]
	*/
	DECLARE @object_1C NVARCHAR(80)
	DECLARE @object_SQL NVARCHAR(80)
	DECLARE @action NVARCHAR(25)
	DECLARE @type NVARCHAR(25)
	DECLARE @additionalParams DATETIME

	DECLARE @table_name NVARCHAR(80)
	DECLARE @table_function NVARCHAR(80)

	SET @sqlstatement = 'DECLARE  settings_cursor CURSOR FORWARD_ONLY FOR 
						 SELECT  s.���������1�
								,m.������������������ as �������������
								,s.��������
								,m.���������� as �����������
								,s.�����������������������
						 FROM '+@database+'.dbo.��������������������������� s
						 INNER JOIN '+@database+'.dbo.MetadataMapping m
						 ON s.���������1� = m.����������
						 WHERE NOT s.�������� = ''�� ������������''
						 AND m.���������� = ''��������'''

	EXECUTE sp_executesql @sqlstatement

	OPEN settings_cursor
	FETCH NEXT FROM settings_cursor 
	INTO @object_1C,@object_SQL,@action,@type, @additionalParams

	WHILE @@FETCH_STATUS = 0
	BEGIN

	PRINT '*****************************************************'
	PRINT @object_1C
	PRINT ''

	/*
	2) ��������� ��������.

	����� ������� �� ��� ��������, ������� ��������� ��������

	�) ����  �������� ��� ����������
	*/
	IF @type = '��������' OR  @type = '����������'

		BEGIN
			/*
			����� �������� ��� �������, ������� ��������� � ���� ��������

			*/
			SET @sqlstatement = 'DECLARE table_cursor CURSOR FORWARD_ONLY FOR
								 SELECT ������������������,���������� FROM '+@database+'.dbo.MetadataMapping
								 WHERE ������������������ LIKE '''+@object_SQL+'_VT%'' OR  ������������������ = '''+@object_SQL+''''

			EXECUTE sp_executesql @sqlstatement
			OPEN table_cursor
			FETCH NEXT FROM table_cursor 
			INTO @table_name,@table_function

			WHILE @@FETCH_STATUS = 0
			BEGIN

			--PRINT @table_name

			/*
			����� ������� �� ��������
			*/
			IF @action LIKE '������� �� ����%'
	
				BEGIN
			
					/*
					������� ������ �� ��������� ������
					*/
					IF @table_function = '��������������'
				
						BEGIN 

							SET @sqlstatement = 'DELETE s FROM  '+@database+'.dbo.'+@table_name+' s
												 INNER JOIN '+@database+'.dbo.'+@object_SQL+' m ON s.'+@object_SQL+'_IDRRef = m._IDRRef AND m._Date_Time < @additionalParams'


							PRINT @sqlstatement
						
							IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

					/*
					������� ������ �� �������� �������
					*/		
					IF @table_function = '��������' AND NOT @action = '������� �� ���� (������ ��������� �����)'

						BEGIN

							SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@table_name+' WHERE _Date_Time < @additionalParams'

							PRINT @sqlstatement
						
							IF @debug = 0  EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

				END

			IF @action LIKE '������� ���������%'

				BEGIN	
				
					/*
					������� ������ �� ��������� ������
					*/
					IF @table_function = '��������������'
					
						BEGIN
					
							/*
							������� ������ �� ��������� ������
							*/
							SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@table_name
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement

						END

					/*
					������� ������ �� �������� �������
					*/	
					IF @table_function = '��������' AND NOT @action = '������� ��������� (������ ��������� �����)'
					
						BEGIN

							SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@table_name
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement

						END

				END

			FETCH NEXT FROM table_cursor --have to fetch again within loop
			INTO  @table_name,@table_function

			END
			CLOSE table_cursor
			DEALLOCATE table_cursor

		END
	/*
	�) ���� ������� ��������
	*/
	IF @type = '���������������'
	/*
	������������ ������ ������� ������ ��������
	*/
		BEGIN

			IF @action = '������� �� ����'

					BEGIN

						SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@object_SQL+' WHERE _Period < @additionalParams'   
					
						PRINT @sqlstatement

						IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

					END

			IF @action = '������� ���������'

				BEGIN

					SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@object_SQL
				
					PRINT @sqlstatement

					IF @debug = 0 EXECUTE sp_executesql @sqlstatement

				END

		END

	/*
	�) ���� ������� ����������
	*/
	IF @type = '�����������������'	
	
		BEGIN

			/*
			������������ ������� ������� ������ ��������
			*/
			IF @action = '������� �� ����'

					BEGIN

						SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@object_SQL+' WHERE _Period < @additionalParams'
					
						PRINT @sqlstatement

						IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

					END

			IF @action = '������� ���������'

				BEGIN

					SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@object_SQL
				
					PRINT @sqlstatement

					IF @debug = 0 EXECUTE sp_executesql @sqlstatement

				END


			/*
			����� ��������� ������� ������
			*/
			SET @sqlstatement = 'DECLARE table_cursor CURSOR FORWARD_ONLY FOR
								 SELECT ������������������,���������� as TABLE_NAME FROM '+@database+'.dbo.MetadataMapping
								 WHERE ���������� = @object_1C AND (����������=''�������'' OR ����������=''�����'')' 


			EXECUTE sp_executesql @sqlstatement, N'@object_1C NVARCHAR(80)', @object_1C = @object_1C
			OPEN table_cursor
			FETCH NEXT FROM table_cursor 
			INTO @table_name,@table_function

			WHILE @@FETCH_STATUS = 0
			BEGIN

			IF @table_function = '�������' OR @table_function = '�����'
			
				BEGIN

					IF @action = '������� �� ����'
				
						BEGIN
					
							SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@table_name+' WHERE _Period < @additionalParams'
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

					IF @action = '������� ���������'
				
						BEGIN
					
							SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@table_name
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement

						END

				END
			
			FETCH NEXT FROM table_cursor --have to fetch again within loop
			INTO @table_name,@table_function

			END
			CLOSE table_cursor
			DEALLOCATE table_cursor

		END
	
	FETCH NEXT FROM settings_cursor --have to fetch again within loop
	INTO @object_1C,@object_SQL,@action,@type, @additionalParams

	END
	CLOSE settings_cursor
	DEALLOCATE settings_cursor

END
GO
