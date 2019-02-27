  declare @backup_type CHAR(1) = 'D' --'D' full, 'L' log
        ;with Radhe as (
            SELECT  @@Servername as [Server_Name],
            B.name as Database_Name, 
            ISNULL(STR(ABS(DATEDIFF(day, GetDate(), MAX(Backup_finish_date)))), 'NEVER') as DaysSinceLastBackup,
            ISNULL(Convert(char(11), MAX(backup_finish_date), 113)+ ' ' + CONVERT(VARCHAR(8),MAX(backup_finish_date),108), 'NEVER') as LastBackupDate
            ,BackupSize_GB=CAST(COALESCE(MAX(A.BACKUP_SIZE),0)/1024.00/1024.00/1024.00 AS NUMERIC(18,2))
            ,BackupSize_MB=CAST(COALESCE(MAX(A.BACKUP_SIZE),0)/1024.00/1024.00 AS NUMERIC(18,2))
            ,media_set_id = MAX(A.media_set_id)
            ,[AVG Backup Duration]= AVG(CAST(DATEDIFF(s, A.backup_start_date, A.backup_finish_date) AS int))
            ,[Longest Backup Duration]= MAX(CAST(DATEDIFF(s, A.backup_start_date, A.backup_finish_date) AS int))
            ,A.type
            FROM sys.databases B 

            LEFT OUTER JOIN msdb.dbo.backupset A 
                         ON A.database_name = B.name 
                        AND A.is_copy_only = 0
                        AND (@backup_type IS NULL OR A.type = @backup_type  )

            GROUP BY B.Name, A.type

        )

         SELECT r.[Server_Name]
               ,r.Database_Name
               ,[Backup Type] = r.type 
               ,r.DaysSinceLastBackup
               ,r.LastBackupDate
               ,r.BackupSize_GB
               ,r.BackupSize_MB
               ,F.physical_device_name
               ,r.[AVG Backup Duration]
               ,r.[Longest Backup Duration]

           FROM Radhe r

            LEFT OUTER JOIN msdb.dbo.backupmediafamily F
                         ON R.media_set_id = F.media_set_id

            ORDER BY r.Server_Name, r.Database_Name