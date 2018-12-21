
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
	1) Выбираем данные из таблицы [НастройкиОбъектовДляОбрезки]
	*/
	DECLARE @object_1C NVARCHAR(80)
	DECLARE @object_SQL NVARCHAR(80)
	DECLARE @action NVARCHAR(25)
	DECLARE @type NVARCHAR(25)
	DECLARE @additionalParams DATETIME

	DECLARE @table_name NVARCHAR(80)
	DECLARE @table_function NVARCHAR(80)

	SET @sqlstatement = 'DECLARE  settings_cursor CURSOR FORWARD_ONLY FOR 
						 SELECT  s.СущностьВ1С
								,m.ИмяТаблицыХранения as СущностьВСУБД
								,s.Действие
								,m.ТипТаблицы as ТипСущности
								,s.ДополнительныеПараметры
						 FROM '+@database+'.dbo.НастройкиОбъектовДляОбрезки s
						 INNER JOIN '+@database+'.dbo.MetadataMapping m
						 ON s.СущностьВ1С = m.Метаданные
						 WHERE NOT s.Действие = ''Не обрабатывать''
						 AND m.Назначение = ''Основная'''

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
	2) Настройка получена.

	Далее смотрим на тип сущность, которую требуется очистить

	а) Если  документ или справочник
	*/
	IF @type = 'Документ' OR  @type = 'Справочник'

		BEGIN
			/*
			Нужно получить все таблицы, которые относятся к этой сущности

			*/
			SET @sqlstatement = 'DECLARE table_cursor CURSOR FORWARD_ONLY FOR
								 SELECT ИмяТаблицыХранения,Назначение FROM '+@database+'.dbo.MetadataMapping
								 WHERE ИмяТаблицыХранения LIKE '''+@object_SQL+'_VT%'' OR  ИмяТаблицыХранения = '''+@object_SQL+''''

			EXECUTE sp_executesql @sqlstatement
			OPEN table_cursor
			FETCH NEXT FROM table_cursor 
			INTO @table_name,@table_function

			WHILE @@FETCH_STATUS = 0
			BEGIN

			--PRINT @table_name

			/*
			Далее смотрим на действие
			*/
			IF @action LIKE 'Удалять до даты%'
	
				BEGIN
			
					/*
					Удаляем данные из табличных частей
					*/
					IF @table_function = 'ТабличнаяЧасть'
				
						BEGIN 

							SET @sqlstatement = 'DELETE s FROM  '+@database+'.dbo.'+@table_name+' s
												 INNER JOIN '+@database+'.dbo.'+@object_SQL+' m ON s.'+@object_SQL+'_IDRRef = m._IDRRef AND m._Date_Time < @additionalParams'


							PRINT @sqlstatement
						
							IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

					/*
					Удаляем данные из основной таблицы
					*/		
					IF @table_function = 'Основная' AND NOT @action = 'Удалять до даты (только табличные части)'

						BEGIN

							SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@table_name+' WHERE _Date_Time < @additionalParams'

							PRINT @sqlstatement
						
							IF @debug = 0  EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

				END

			IF @action LIKE 'Удалять полностью%'

				BEGIN	
				
					/*
					Удаляем данные из табличных частей
					*/
					IF @table_function = 'ТабличнаяЧасть'
					
						BEGIN
					
							/*
							Удаляем данные из табличных частей
							*/
							SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@table_name
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement

						END

					/*
					Удаляем данные из основной таблицы
					*/	
					IF @table_function = 'Основная' AND NOT @action = 'Удалять полностью (только табличные части)'
					
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
	б) Если регистр сведений
	*/
	IF @type = 'РегистрСведений'
	/*
	Обрабатываем только таблицу самого регистра
	*/
		BEGIN

			IF @action = 'Удалять до даты'

					BEGIN

						SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@object_SQL+' WHERE _Period < @additionalParams'   
					
						PRINT @sqlstatement

						IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

					END

			IF @action = 'Удалять полностью'

				BEGIN

					SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@object_SQL
				
					PRINT @sqlstatement

					IF @debug = 0 EXECUTE sp_executesql @sqlstatement

				END

		END

	/*
	б) Если регистр накопления
	*/
	IF @type = 'РегистрНакопления'	
	
		BEGIN

			/*
			Обрабатываем сначала таблицу самого регистра
			*/
			IF @action = 'Удалять до даты'

					BEGIN

						SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@object_SQL+' WHERE _Period < @additionalParams'
					
						PRINT @sqlstatement

						IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

					END

			IF @action = 'Удалять полностью'

				BEGIN

					SET @sqlstatement = 'truncate table '+@database+'.dbo.'+@object_SQL
				
					PRINT @sqlstatement

					IF @debug = 0 EXECUTE sp_executesql @sqlstatement

				END


			/*
			Затем подчищаем таблицу итогов
			*/
			SET @sqlstatement = 'DECLARE table_cursor CURSOR FORWARD_ONLY FOR
								 SELECT ИмяТаблицыХранения,Назначение as TABLE_NAME FROM '+@database+'.dbo.MetadataMapping
								 WHERE Метаданные = @object_1C AND (Назначение=''Обороты'' OR Назначение=''Итоги'')' 


			EXECUTE sp_executesql @sqlstatement, N'@object_1C NVARCHAR(80)', @object_1C = @object_1C
			OPEN table_cursor
			FETCH NEXT FROM table_cursor 
			INTO @table_name,@table_function

			WHILE @@FETCH_STATUS = 0
			BEGIN

			IF @table_function = 'Обороты' OR @table_function = 'Итоги'
			
				BEGIN

					IF @action = 'Удалять до даты'
				
						BEGIN
					
							SET @sqlstatement = 'DELETE FROM  '+@database+'.dbo.'+@table_name+' WHERE _Period < @additionalParams'
						
							PRINT @sqlstatement

							IF @debug = 0 EXECUTE sp_executesql @sqlstatement, N'@additionalParams DateTime', @additionalParams = @additionalParams

						END

					IF @action = 'Удалять полностью'
				
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
