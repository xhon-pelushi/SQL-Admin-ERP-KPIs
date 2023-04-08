-- Power BI Data Transformation Script
-- Transforms staging data into Power BI-ready format

-- Create Power BI fact table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PowerBI_SalesFact')
BEGIN
    CREATE TABLE [dbo].[PowerBI_SalesFact] (
        [FactID] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [OrderDateKey] INT,
        [CustomerKey] INT,
        [ProductKey] INT,
        [SalesRepKey] INT,
        [OrderID] INT,
        [Quantity] DECIMAL(19,6),
        [UnitPrice] DECIMAL(19,6),
        [LineTotal] DECIMAL(19,6),
        [OrderTotal] DECIMAL(19,6),
        [CreatedDate] DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX IX_PowerBI_SalesFact_DateKey ON [PowerBI_SalesFact](OrderDateKey);
    CREATE INDEX IX_PowerBI_SalesFact_CustomerKey ON [PowerBI_SalesFact](CustomerKey);
END
GO

-- Create date dimension
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PowerBI_DateDimension')
BEGIN
    CREATE TABLE [dbo].[PowerBI_DateDimension] (
        [DateKey] INT PRIMARY KEY,
        [Date] DATE,
        [Year] INT,
        [Quarter] INT,
        [Month] INT,
        [MonthName] NVARCHAR(20),
        [Week] INT,
        [DayOfYear] INT,
        [DayOfMonth] INT,
        [DayOfWeek] INT,
        [DayName] NVARCHAR(20),
        [IsWeekend] BIT,
        [IsHoliday] BIT
    );
    
    -- Populate date dimension (last 5 years)
    DECLARE @StartDate DATE = DATEADD(YEAR, -5, GETDATE());
    DECLARE @EndDate DATE = DATEADD(YEAR, 1, GETDATE());
    DECLARE @CurrentDate DATE = @StartDate;
    
    WHILE @CurrentDate <= @EndDate
    BEGIN
        INSERT INTO [dbo].[PowerBI_DateDimension] (
            DateKey, Date, Year, Quarter, Month, MonthName, Week,
            DayOfYear, DayOfMonth, DayOfWeek, DayName, IsWeekend, IsHoliday
        )
        VALUES (
            CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
            @CurrentDate,
            YEAR(@CurrentDate),
            DATEPART(QUARTER, @CurrentDate),
            MONTH(@CurrentDate),
            DATENAME(MONTH, @CurrentDate),
            DATEPART(WEEK, @CurrentDate),
            DATEPART(DAYOFYEAR, @CurrentDate),
            DAY(@CurrentDate),
            DATEPART(WEEKDAY, @CurrentDate),
            DATENAME(WEEKDAY, @CurrentDate),
            CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END,
            0 -- IsHoliday (would need holiday calendar)
        );
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END;
END
GO

-- Transform and load sales fact data
INSERT INTO [dbo].[PowerBI_SalesFact] (
    OrderDateKey,
    CustomerKey,
    ProductKey,
    SalesRepKey,
    OrderID,
    Quantity,
    UnitPrice,
    LineTotal,
    OrderTotal
)
SELECT 
    CAST(FORMAT(o.OrderDate, 'yyyyMMdd') AS INT) AS OrderDateKey,
    o.CustomerID AS CustomerKey,
    od.ProductID AS ProductKey,
    o.SalesRepID AS SalesRepKey,
    o.OrderID,
    od.Quantity,
    od.UnitPrice,
    od.LineTotal,
    o.TotalAmount AS OrderTotal
FROM Orders o
INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
WHERE o.OrderDate >= DATEADD(DAY, -30, GETDATE())
    AND NOT EXISTS (
        SELECT 1 FROM [dbo].[PowerBI_SalesFact] f
        WHERE f.OrderID = o.OrderID AND f.ProductKey = od.ProductID
    );
GO






































