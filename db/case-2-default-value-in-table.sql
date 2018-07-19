/*
	此範例將訂單編號設定為欄位預設內容
*/
USE [eShopWithOrders]
GO

DROP TABLE [Orders].[OrderMains]
GO

CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT NOT NULL,
	[Schema]		CHAR(15) DEFAULT ([Orders].[GetOrderSchema]()),
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

		SET @IsSuccess = 0

		SET @OrderNo = (NEXT VALUE FOR [Orders].[OrderMainSeq])

		INSERT INTO [Orders].[OrderMains] (
			[No]
		) VALUES (
			@OrderNo
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