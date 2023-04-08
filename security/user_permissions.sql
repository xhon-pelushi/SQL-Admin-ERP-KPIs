-- User Permission Management Script
-- Role-based access control for ERP database

-- Create database roles
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ERP_ReadOnly')
    CREATE ROLE [ERP_ReadOnly];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ERP_Reporting')
    CREATE ROLE [ERP_Reporting];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ERP_DataEntry')
    CREATE ROLE [ERP_DataEntry];
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ERP_Admin')
    CREATE ROLE [ERP_Admin];
GO

-- Grant permissions to ReadOnly role
GRANT SELECT ON SCHEMA::[dbo] TO [ERP_ReadOnly];
DENY INSERT, UPDATE, DELETE ON SCHEMA::[dbo] TO [ERP_ReadOnly];
GO

-- Grant permissions to Reporting role
GRANT SELECT ON SCHEMA::[dbo] TO [ERP_Reporting];
GRANT EXECUTE ON SCHEMA::[dbo] TO [ERP_Reporting];
GRANT SELECT ON [dbo].[PowerBI_SalesFact] TO [ERP_Reporting];
GRANT SELECT ON [dbo].[PowerBI_DateDimension] TO [ERP_Reporting];
DENY INSERT, UPDATE, DELETE ON SCHEMA::[dbo] TO [ERP_Reporting];
GO

-- Grant permissions to DataEntry role
GRANT SELECT, INSERT, UPDATE ON SCHEMA::[dbo] TO [ERP_DataEntry];
GRANT EXECUTE ON SCHEMA::[dbo] TO [ERP_DataEntry];
DENY DELETE ON SCHEMA::[dbo] TO [ERP_DataEntry];
GO

-- Grant permissions to Admin role
GRANT CONTROL ON SCHEMA::[dbo] TO [ERP_Admin];
GO

-- Create user mapping function
CREATE OR ALTER PROCEDURE [dbo].[sp_AssignUserRole]
    @Username NVARCHAR(128),
    @RoleName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if user exists
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @Username)
    BEGIN
        -- Create database user from login
        DECLARE @SQL NVARCHAR(MAX) = N'CREATE USER [' + @Username + N'] FOR LOGIN [' + @Username + N'];';
        EXEC sp_executesql @SQL;
    END
    
    -- Check if role exists
    IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = @RoleName AND type = 'R')
    BEGIN
        RAISERROR('Role %s does not exist', 16, 1, @RoleName);
        RETURN;
    END
    
    -- Add user to role
    DECLARE @RoleSQL NVARCHAR(MAX) = N'ALTER ROLE [' + @RoleName + N'] ADD MEMBER [' + @Username + N'];';
    EXEC sp_executesql @RoleSQL;
    
    PRINT 'User ' + @Username + ' added to role ' + @RoleName;
END;
GO

-- Example: Create sample users
-- EXEC [dbo].[sp_AssignUserRole] 'DOMAIN\ReportingUser1', 'ERP_Reporting';
-- EXEC [dbo].[sp_AssignUserRole] 'DOMAIN\DataEntryUser1', 'ERP_DataEntry';
-- EXEC [dbo].[sp_AssignUserRole] 'DOMAIN\AdminUser1', 'ERP_Admin';

-- Audit logging table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAccessAudit')
BEGIN
    CREATE TABLE [dbo].[UserAccessAudit] (
        [AuditID] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [Username] NVARCHAR(128),
        [DatabaseName] NVARCHAR(128),
        [SchemaName] NVARCHAR(128),
        [ObjectName] NVARCHAR(128),
        [Action] NVARCHAR(50),
        [Timestamp] DATETIME DEFAULT GETDATE(),
        [IPAddress] NVARCHAR(50),
        [ApplicationName] NVARCHAR(128)
    );
    
    CREATE INDEX IX_UserAccessAudit_Username ON [UserAccessAudit](Username);
    CREATE INDEX IX_UserAccessAudit_Timestamp ON [UserAccessAudit](Timestamp);
END
GO













































