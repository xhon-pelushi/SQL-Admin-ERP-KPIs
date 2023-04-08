-- On-Time Delivery (OTD) Reporting Stored Procedure
-- Calculates OTD metrics for manufacturing orders

CREATE PROCEDURE [dbo].[sp_GetOTDReport]
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @CustomerID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Default to last 30 days if not specified
    IF @StartDate IS NULL
        SET @StartDate = DATEADD(DAY, -30, GETDATE());
    IF @EndDate IS NULL
        SET @EndDate = GETDATE();
    
    -- Calculate OTD metrics
    WITH OrderMetrics AS (
        SELECT 
            o.OrderID,
            o.CustomerID,
            c.CustomerName,
            o.OrderDate,
            o.PromisedDeliveryDate,
            o.ActualDeliveryDate,
            o.OrderStatus,
            CASE 
                WHEN o.ActualDeliveryDate IS NULL AND o.PromisedDeliveryDate < GETDATE() THEN 'Late'
                WHEN o.ActualDeliveryDate IS NULL THEN 'Pending'
                WHEN o.ActualDeliveryDate <= o.PromisedDeliveryDate THEN 'On-Time'
                ELSE 'Late'
            END AS DeliveryStatus,
            DATEDIFF(DAY, o.PromisedDeliveryDate, ISNULL(o.ActualDeliveryDate, GETDATE())) AS DaysVariance,
            o.TotalAmount
        FROM Orders o
        INNER JOIN Customers c ON o.CustomerID = c.CustomerID
        WHERE o.OrderDate BETWEEN @StartDate AND @EndDate
            AND (@CustomerID IS NULL OR o.CustomerID = @CustomerID)
    )
    SELECT 
        OrderID,
        CustomerID,
        CustomerName,
        OrderDate,
        PromisedDeliveryDate,
        ActualDeliveryDate,
        DeliveryStatus,
        DaysVariance,
        TotalAmount,
        CASE 
            WHEN DeliveryStatus = 'On-Time' THEN 1 
            ELSE 0 
        END AS IsOnTime
    FROM OrderMetrics
    ORDER BY OrderDate DESC;
    
    -- Summary statistics
    SELECT 
        COUNT(*) AS TotalOrders,
        SUM(CASE WHEN DeliveryStatus = 'On-Time' THEN 1 ELSE 0 END) AS OnTimeOrders,
        SUM(CASE WHEN DeliveryStatus = 'Late' THEN 1 ELSE 0 END) AS LateOrders,
        SUM(CASE WHEN DeliveryStatus = 'Pending' THEN 1 ELSE 0 END) AS PendingOrders,
        CAST(SUM(CASE WHEN DeliveryStatus = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS OTDRate,
        AVG(CASE WHEN DeliveryStatus = 'Late' THEN DaysVariance ELSE NULL END) AS AvgDaysLate,
        SUM(TotalAmount) AS TotalRevenue
    FROM OrderMetrics;
END;
GO

-- Grant execute permission
GRANT EXECUTE ON [dbo].[sp_GetOTDReport] TO [ReportingUsers];
GO
















































