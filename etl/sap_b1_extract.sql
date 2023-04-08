-- SAP Business One Data Extraction Script
-- Extracts data from SAP B1 database for ETL processing

-- Create staging table for sales orders
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Staging_SAPB1_SalesOrders')
BEGIN
    CREATE TABLE [dbo].[Staging_SAPB1_SalesOrders] (
        [DocEntry] INT,
        [DocNum] INT,
        [CardCode] NVARCHAR(50),
        [CardName] NVARCHAR(200),
        [DocDate] DATETIME,
        [DocDueDate] DATETIME,
        [DocTotal] DECIMAL(19,6),
        [DocStatus] NVARCHAR(1),
        [ExtractedDate] DATETIME DEFAULT GETDATE(),
        PRIMARY KEY ([DocEntry])
    );
END
GO

-- Extract sales orders from SAP B1
-- Note: Replace 'SAPB1_DB' with actual SAP B1 database name
INSERT INTO [dbo].[Staging_SAPB1_SalesOrders] (
    DocEntry,
    DocNum,
    CardCode,
    CardName,
    DocDate,
    DocDueDate,
    DocTotal,
    DocStatus
)
SELECT 
    o.DocEntry,
    o.DocNum,
    o.CardCode,
    o.CardName,
    o.DocDate,
    o.DocDueDate,
    o.DocTotal,
    o.DocStatus
FROM [SAPB1_DB].[dbo].[ORDR] o
WHERE o.DocDate >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
    AND NOT EXISTS (
        SELECT 1 FROM [dbo].[Staging_SAPB1_SalesOrders] s
        WHERE s.DocEntry = o.DocEntry
    );
GO

-- Extract line items
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Staging_SAPB1_SalesOrderLines')
BEGIN
    CREATE TABLE [dbo].[Staging_SAPB1_SalesOrderLines] (
        [DocEntry] INT,
        [LineNum] INT,
        [ItemCode] NVARCHAR(50),
        [ItemDescription] NVARCHAR(200),
        [Quantity] DECIMAL(19,6),
        [UnitPrice] DECIMAL(19,6),
        [LineTotal] DECIMAL(19,6),
        [ExtractedDate] DATETIME DEFAULT GETDATE(),
        PRIMARY KEY ([DocEntry], [LineNum])
    );
END
GO

INSERT INTO [dbo].[Staging_SAPB1_SalesOrderLines] (
    DocEntry,
    LineNum,
    ItemCode,
    ItemDescription,
    Quantity,
    UnitPrice,
    LineTotal
)
SELECT 
    ol.DocEntry,
    ol.LineNum,
    ol.ItemCode,
    ol.Dscription,
    ol.Quantity,
    ol.Price,
    ol.LineTotal
FROM [SAPB1_DB].[dbo].[RDR1] ol
INNER JOIN [dbo].[Staging_SAPB1_SalesOrders] o ON ol.DocEntry = o.DocEntry
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[Staging_SAPB1_SalesOrderLines] s
    WHERE s.DocEntry = ol.DocEntry AND s.LineNum = ol.LineNum
);
GO







































