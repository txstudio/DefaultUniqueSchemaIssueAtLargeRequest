/*
	此範例訂單編號將從 StoredProcedure 取得後新增
*/
USE [eShopWithOrders]
GO

DROP TABLE [Orders].[OrderMains]
GO

CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT NOT NULL,
	[Schema]		CHAR(15) NOT NULL,
	[OrderDate]		DATETIMEOFFSET DEFAULT (SYSDATETIMEOFFSET())

	CONSTRAINT [pk_Orders_OrderMains] PRIMARY KEY ([No]),

	CONSTRAINT [un_Orders_OrderMains_Schema] UNIQUE ([Schema])
)
GO

ALTER PROCEDURE [Orders].[AddOrder]
	@IsSuccess BIT OUT
AS
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE @OrderNo INT
		DECLARE @Schema CHAR(15)

		SET @IsSuccess = 0

		SET @OrderNo = (NEXT VALUE FOR [Orders].[OrderMainSeq])
		SET @Schema = (SELECT [Orders].[GetOrderSchema]())

		INSERT INTO [Orders].[OrderMains] (
			[No]
			,[Schema]
		) VALUES (
			@OrderNo
			,@Schema
		)

		SET @IsSuccess = 1

		COMMIT
	END TRY

	BEGIN CATCH
		ROLLBACK
		
		EXEC [Events].[AddEventDatabaseError] 
		
		SET @IsSuccess = 0
	END CATCH
GO