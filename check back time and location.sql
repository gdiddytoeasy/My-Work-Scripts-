SELECT p.database_name AS DatabaseName,
p.backup_start_date AS 'Backup Start Time',
p.backup_finish_date AS 'Backup Finish Time',
CAST((DATEDIFF(MINUTE, p.backup_start_date, p.backup_finish_date)) AS varchar)+ ' min  '+ CAST((DATEDIFF(ss, p.backup_start_date, p.backup_finish_date)) AS varchar) + ' sec ' AS [Total Time] ,
CASE p.type
WHEN 'D' THEN 'Full '
--WHEN 'I' THEN 'Diffrential'
--WHEN 'L' THEN 'Log'
END AS 'Backup Type',
Cast(p.backup_size/1024/1024 AS numeric(10,2)) AS 'Backup Size(MB)' ,
a.physical_device_name AS 'Physical File location'
FROM msdb..backupmediafamily a,
msdb..backupset p
WHERE a.media_set_id=p.media_set_id
 
-- Uncomment below line and Replace <Database name> with DB you want to check backup history
--and p.database_name='Database name'
 
-- Uncomment below line and replace start and end dates with dates you want to check history
--and p.backup_start_date>'2013-01-20' and p.backup_start_date<'2013-01-25 23:59:59'
 
--Uncomment below line to see only the full backups, replace with 'I' to check diffrential and 'L' to check only Log backups.
--and p.type='D'
 
ORDER BY p.backup_start_date DESC