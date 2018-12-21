USE [dubrovinom_plazma]
GO

DECLARE @RC int
DECLARE @SourceTable nvarchar(255)
DECLARE @DestinationTable nvarchar(255)
DECLARE @PartionField nvarchar(255)
DECLARE @SourceSchema nvarchar(255)
DECLARE @DestinationSchema nvarchar(255)
DECLARE @RecreateIfExists bit

SET @SourceTable = '_Document180';
SET @DestinationTable = '_Document180_NEW';
SET @RecreateIfExists = 1;
SET @SourceSchema = 'dbo';
SET @DestinationSchema = 'dbo';
-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[spCloneTableStructure] 
   @SourceTable
  ,@DestinationTable
  ,@PartionField
  ,@SourceSchema
  ,@DestinationSchema
  ,@RecreateIfExists
GO


