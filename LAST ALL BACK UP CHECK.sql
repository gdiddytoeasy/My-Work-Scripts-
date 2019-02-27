use msdb
go
SELECT
  DISTINCT
        a.Name AS DatabaseName ,
        CONVERT(SYSNAME, DATABASEPROPERTYEX(a.name, 'Recovery')) RecoveryModel ,
        COALESCE(( SELECT   CONVERT(VARCHAR(12), MAX(backup_finish_date), 101)
                   FROM     msdb.dbo.backupset
                   WHERE    database_name = a.name
                            AND type = 'D'
                            AND is_copy_only = '0'
                 ), 'No Full') AS 'Full' ,
        COALESCE(( SELECT   CONVERT(VARCHAR(12), MAX(backup_finish_date), 101)
                   FROM     msdb.dbo.backupset
                   WHERE    database_name = a.name
                            AND type = 'I'
                            AND is_copy_only = '0'
                 ), 'No Diff') AS 'Diff' ,
        COALESCE(( SELECT   CONVERT(VARCHAR(20), MAX(backup_finish_date), 120)
                   FROM     msdb.dbo.backupset
                   WHERE    database_name = a.name
                            AND type = 'L'
                 ), 'No Log') AS 'LastLog' ,
        COALESCE(( SELECT   CONVERT(VARCHAR(20), backup_finish_date, 120)
                   FROM     ( SELECT    ROW_NUMBER() OVER ( ORDER BY backup_finish_date DESC ) AS 'rownum' ,
                                        backup_finish_date
                              FROM      msdb.dbo.backupset
                              WHERE     database_name = a.name
                                        AND type = 'L'
                            ) withrownum
                   WHERE    rownum = 2
                 ), 'No Log') AS 'LastLog2'
FROM    sys.databases a
        LEFT OUTER JOIN msdb.dbo.backupset b ON b.database_name = a.name
WHERE   a.name <> 'tempdb'
        AND a.state_desc = 'online'
GROUP BY a.Name ,
        a.compatibility_level
ORDER BY a.name