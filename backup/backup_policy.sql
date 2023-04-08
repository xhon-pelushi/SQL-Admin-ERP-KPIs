-- Backup Policy Configuration
-- Automated backup procedures for ERP databases

-- Full backup job (daily at 2 AM)
USE msdb;
GO

IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'FullBackup_Daily')
BEGIN
    EXEC sp_delete_job @job_name = 'FullBackup_Daily';
END
GO

EXEC sp_add_job @job_name = 'FullBackup_Daily';
EXEC sp_add_jobstep 
    @job_name = 'FullBackup_Daily',
    @step_name = 'Backup_Database',
    @subsystem = 'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500) = ''C:\Backups\ERP_Full_' + CONVERT(VARCHAR(10), GETDATE(), 112) + '.bak'';
BACKUP DATABASE [ERP_Database] 
TO DISK = @BackupPath
WITH FORMAT, INIT, NAME = ''Full Backup of ERP Database'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
',
    @database_name = 'ERP_Database';
EXEC sp_add_schedule 
    @schedule_name = 'Daily_2AM',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @active_start_time = 20000; -- 2:00 AM
EXEC sp_attach_schedule 
    @job_name = 'FullBackup_Daily',
    @schedule_name = 'Daily_2AM';
EXEC sp_add_jobserver @job_name = 'FullBackup_Daily';
GO

-- Differential backup job (every 6 hours)
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'DifferentialBackup_Hourly')
BEGIN
    EXEC sp_delete_job @job_name = 'DifferentialBackup_Hourly';
END
GO

EXEC sp_add_job @job_name = 'DifferentialBackup_Hourly';
EXEC sp_add_jobstep 
    @job_name = 'DifferentialBackup_Hourly',
    @step_name = 'Differential_Backup',
    @subsystem = 'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500) = ''C:\Backups\ERP_Diff_' + CONVERT(VARCHAR(10), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), '':'', '''') + '.bak'';
BACKUP DATABASE [ERP_Database] 
TO DISK = @BackupPath
WITH DIFFERENTIAL, FORMAT, INIT, NAME = ''Differential Backup of ERP Database'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
',
    @database_name = 'ERP_Database';
EXEC sp_add_schedule 
    @schedule_name = 'Every6Hours',
    @freq_type = 4,
    @freq_subday_type = 8, -- Hours
    @freq_subday_interval = 6,
    @active_start_time = 0;
EXEC sp_attach_schedule 
    @job_name = 'DifferentialBackup_Hourly',
    @schedule_name = 'Every6Hours';
EXEC sp_add_jobserver @job_name = 'DifferentialBackup_Hourly';
GO

-- Transaction log backup job (every 15 minutes)
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'LogBackup_15Min')
BEGIN
    EXEC sp_delete_job @job_name = 'LogBackup_15Min';
END
GO

EXEC sp_add_job @job_name = 'LogBackup_15Min';
EXEC sp_add_jobstep 
    @job_name = 'LogBackup_15Min',
    @step_name = 'Log_Backup',
    @subsystem = 'TSQL',
    @command = N'
DECLARE @BackupPath NVARCHAR(500) = ''C:\Backups\ERP_Log_' + CONVERT(VARCHAR(10), GETDATE(), 112) + '_' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), '':'', '''') + '.trn'';
BACKUP LOG [ERP_Database] 
TO DISK = @BackupPath
WITH FORMAT, INIT, NAME = ''Transaction Log Backup'', SKIP, NOREWIND, NOUNLOAD, STATS = 10;
',
    @database_name = 'ERP_Database';
EXEC sp_add_schedule 
    @schedule_name = 'Every15Minutes',
    @freq_type = 4,
    @freq_subday_type = 4, -- Minutes
    @freq_subday_interval = 15,
    @active_start_time = 0;
EXEC sp_attach_schedule 
    @job_name = 'LogBackup_15Min',
    @schedule_name = 'Every15Minutes';
EXEC sp_add_jobserver @job_name = 'LogBackup_15Min';
GO

-- Cleanup old backups (retain 30 days)
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = 'CleanupOldBackups')
BEGIN
    EXEC sp_delete_job @job_name = 'CleanupOldBackups';
END
GO

EXEC sp_add_job @job_name = 'CleanupOldBackups';
EXEC sp_add_jobstep 
    @job_name = 'CleanupOldBackups',
    @step_name = 'Delete_Old_Backups',
    @subsystem = 'PowerShell',
    @command = N'Get-ChildItem -Path "C:\Backups" -Filter "*.bak","*.trn" | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | Remove-Item -Force';
EXEC sp_add_schedule 
    @schedule_name = 'Daily_Cleanup',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 30000; -- 3:00 AM
EXEC sp_attach_schedule 
    @job_name = 'CleanupOldBackups',
    @schedule_name = 'Daily_Cleanup';
EXEC sp_add_jobserver @job_name = 'CleanupOldBackups';
GO













































