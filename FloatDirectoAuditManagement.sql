USE [msdb]
GO

BEGIN TRANSACTION

DECLARE @Login varchar(200)
DECLARE @OutputFileName varchar(200)

SET @Login = N'DBAsa'
SET	@OutputFileName = N'E:\FloatDirector\ExportJobOutput.txt'


DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF NOT EXISTS(SELECT	J.*, C.name
FROM	msdb.dbo.sysjobs j
		JOIN msdb.dbo.syscategories c ON c.category_id=j.category_id
WHERE	j.name=N'Audit_Data_Management_System'
		AND c.name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN

	--PRINT 'Adding scheduled job.'
	DECLARE @jobId BINARY(16)
	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Audit_Data_Management_System', 
			@enabled=1, 
			@notify_level_eventlog=0, 
			@notify_level_email=0, 
			@notify_level_netsend=0, 
			@notify_level_page=0, 
			@delete_level=0, 
			@description=N'Execute the procedure to Export the Float Director .IMP files.', 
			@category_name=N'[Uncategorized (Local)]', 
			@owner_login_name= @Login, @job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clear all tables in the FloatDirectorAudit database', 
			@step_id=1, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command= N'DECLARE C1 CURSOR FOR 
	SELECT NAME FROM sysobjects WHERE TYPE = ''U'' AND NAME LIKE ''%_AUDIT''
	DECLARE @NAME VARCHAR(128),
			@CMD VARCHAR(2000)

	OPEN C1
	FETCH C1 INTO @NAME

	WHILE @@FETCH_STATUS <> -1
	BEGIN
		SET @CMD = ''truncate table '' + @NAME 
		--PRINT @CMD
		EXEC( @CMD )
		FETCH C1 INTO @NAME
	END
	CLOSE C1
	DEALLOCATE C1', 
			@database_name=N'FloatDirectorAudit', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Call the LoadAuditData procedure in the FloatDirectorAudit database', 
			@step_id=2, 
			@cmdexec_success_code=0, 
			@on_success_action=3, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'EXEC LoadAuditData ''FloatDirector''', 
			@database_name=N'FloatDirectorAudit', 
			@output_file_name=@OutputFileName, 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Delete old Data', 
			@step_id=3, 
			@cmdexec_success_code=0, 
			@on_success_action=1, 
			@on_success_step_id=0, 
			@on_fail_action=2, 
			@on_fail_step_id=0, 
			@retry_attempts=0, 
			@retry_interval=0, 
			@os_run_priority=0, @subsystem=N'TSQL', 
			@command=N'EXEC [ClearAuditTables] Null, Null', 
			@database_name=N'FloatDirector', 
			@flags=0
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monthly Backup of Audit Data', 
			@enabled=1, 
			@freq_type=16, 
			@freq_interval=1, 
			@freq_subday_type=1, 
			@freq_subday_interval=0, 
			@freq_relative_interval=0, 
			@freq_recurrence_factor=1, 
			@active_start_date=20130311, 
			@active_end_date=99991231, 
			@active_start_time=10000, 
			@active_end_time=235959, 
			@schedule_uid=N'55b25903-fc91-4bab-b2b4-0111c4969016'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
