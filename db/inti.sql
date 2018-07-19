/*
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'eShopWithOrders'
GO

USE [master]
GO

ALTER DATABASE [eShopWithOrders]
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

USE [master]
GO

DROP DATABASE [eShopWithOrders]
GO

USE [master]
GO
*/
CREATE DATABASE [eShopWithOrders]
GO

USE [eShopWithOrders]
GO

CREATE SCHEMA [Orders]
GO

CREATE SCHEMA [Events]
GO


--儲存預存程序錯誤的事件紀錄資料表
CREATE TABLE [Events].[EventDatabaseErrorLog] (
	[No]                INT IDENTITY(1, 1),
	[ErrorTime]         DATETIME DEFAULT (SYSDATETIMEOFFSET()),
	[ErrorDatabase]     NVARCHAR(100),
	[LoginName]         NVARCHAR(100),
	[UserName]          NVARCHAR(128),
	[ErrorNumber]       INT,
	[ErrorSeverity]     INT,
	[ErrorState]        INT,
	[ErrorProcedure]    NVARCHAR(130),
	[ErrorLine]         INT,
	[ErrorMessage]      NVARCHAR(MAX),
	
    CONSTRAINT [PK_Events_DatabaseErrorLog] PRIMARY KEY ([No] ASC)
)
GO


CREATE PROCEDURE [Events].[AddEventDatabaseError] 
    @No INT = 0 OUTPUT
AS
    DECLARE @seed INT

    SET NOCOUNT ON

    BEGIN TRY
        IF ERROR_NUMBER() IS NULL
        BEGIN
            RETURN
        END

        --
        --如果有進行中的交易正在使用時不進行記錄
        -- (尚未 rollback 或 commit)
        --
        IF XACT_STATE() = (- 1)
        BEGIN
            RETURN
        END

        INSERT INTO [Events].[EventDatabaseErrorLog] (
            [ErrorDatabase]
            ,[LoginName]
            ,[UserName]
            ,[ErrorNumber]
            ,[ErrorSeverity]
            ,[ErrorState]
            ,[ErrorProcedure]
            ,[ErrorLine]
            ,[ErrorMessage]
            )
        VALUES (
            CONVERT(NVARCHAR(100), DB_NAME())
            ,CONVERT(NVARCHAR(100), SYSTEM_USER)
            ,CONVERT(NVARCHAR(128), CURRENT_USER)
            ,ERROR_NUMBER()
            ,ERROR_SEVERITY()
            ,ERROR_STATE()
            ,ERROR_PROCEDURE()
            ,ERROR_LINE()
            ,ERROR_MESSAGE()
            )
    END TRY

    BEGIN CATCH
        RETURN (- 1)
    END CATCH
GO


--取得新一筆訂單要儲存的訂單編號 (yyyyMMdd9999999)
CREATE FUNCTION [Orders].[GetOrderSchema]()
	RETURNS CHAR(15)
AS
BEGIN
	DECLARE @Schema CHAR(15)
	DECLARE @LastCode CHAR(8)
	DECLARE @LastIdentity CHAR(7)
	DECLARE @NewCode CHAR(8)
	DECLARE @Identity INT

	SET @Schema = (
		SELECT TOP(1) [Schema] 
		FROM [Orders].[OrderMains]
		ORDER BY [Schema] DESC
	)

	SET @NewCode = CONVERT(VARCHAR,GETDATE(),112)
	SET @LastCode = LEFT(@Schema,8)
	SET @LastIdentity = RIGHT(@Schema,7)

	SET @Identity = 0

	If @NewCode = @LastCode 
		SET @Identity = CONVERT(INT,@LastIdentity)

	SET @Identity = @Identity + 1

	RETURN (@NewCode+RIGHT('000000'+CONVERT(VARCHAR(7),@Identity),7))
END
GO 

CREATE SEQUENCE [Orders].[OrderMainSeq] 
	AS INT
	START WITH 1
	INCREMENT BY 1
GO


CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT NOT NULL,
	[Schema]		CHAR(15),
	[OrderDate]		DATETIMEOFFSET DEFAULT (SYSDATETIMEOFFSET())

	CONSTRAINT [pk_Orders_OrderMains] PRIMARY KEY ([No]),

	CONSTRAINT [un_Orders_OrderMains_Schema] UNIQUE ([Schema])
)
GO

/*
	依情境執行
	case-1-get-schema-in-procedure.sql
	case-2-default-value-in-table.sql
	
	更換不同設計方式
*/
CREATE PROCEDURE [Orders].[AddOrder]
	@IsSuccess BIT OUT
AS
	SET @IsSuccess = 0
GO