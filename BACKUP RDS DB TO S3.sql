exec msdb.dbo.rds_backup_database 
       @source_db_name='dbFPPM', 
       @s3_arn_to_backup_to='arn:aws:s3:::cma-database-restores-prod/dbFPPM.bak', 
       @overwrite_S3_backup_file=1,
       @type='FULL';
