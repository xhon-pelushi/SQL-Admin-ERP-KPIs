-- Sales KPIs Stored Procedure
-- Calculates key sales performance indicators

CREATE PROCEDURE [dbo].[sp_GetSalesKPIs]
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @SalesRepID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(MONTH, -1, GETDATE());
    IF @EndDate IS NULL
        SET @EndDate = GETDATE();
    
    -- Sales Summary
    SELECT 
        sr.SalesRepID,
        sr.SalesRepName,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustomerID) AS UniqueCustomers,
        SUM(o.TotalAmount) AS TotalRevenue,
        AVG(o.TotalAmount) AS AvgOrderValue,
        SUM(o.TotalAmount) / NULLIF(COUNT(DISTINCT DAY(o.OrderDate)), 0) AS DailyAvgRevenue,
        MAX(o.OrderDate) AS LastOrderDate
    FROM Orders o
    INNER JOIN SalesReps sr ON o.SalesRepID = sr.SalesRepID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
        AND (@SalesRepID IS NULL OR sr.SalesRepID = @SalesRepID)
    GROUP BY sr.SalesRepID, sr.SalesRepName;
    
    -- Product Sales Breakdown
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Category,
        SUM(od.Quantity) AS TotalQuantity,
        SUM(od.Quantity * od.UnitPrice) AS TotalRevenue,
        AVG(od.UnitPrice) AS AvgUnitPrice,
        COUNT(DISTINCT od.OrderID) AS OrderCount
    FROM OrderDetails od
    INNER JOIN Products p ON od.ProductID = p.ProductID
    INNER JOIN Orders o ON od.OrderID = o.OrderID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY p.ProductID, p.ProductName, p.Category
    ORDER BY TotalRevenue DESC;
    
    -- Customer Analysis
    SELECT 
        c.CustomerID,
        c.CustomerName,
        COUNT(o.OrderID) AS OrderCount,
        SUM(o.TotalAmount) AS TotalSpent,
        AVG(o.TotalAmount) AS AvgOrderValue,
        MAX(o.OrderDate) AS LastPurchaseDate
    FROM Customers c
    INNER JOIN Orders o ON c.CustomerID = o.CustomerID
    WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
    GROUP BY c.CustomerID, c.CustomerName
    ORDER BY TotalSpent DESC;
END;
GO

GRANT EXECUTE ON [dbo].[sp_GetSalesKPIs] TO [ReportingUsers];
GO









































