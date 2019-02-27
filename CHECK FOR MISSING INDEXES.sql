SELECT TOP 25
	 ROUND(DMIGS.avg_total_user_cost * DMIGS.avg_user_impact * (DMIGS.user_seeks + DMIGS.user_scans),0) AS TotalCost
	 ,DMID.[statement] AS TableName
	 ,equality_columns
	 ,inequality_columns
	 ,included_columns
FROM sys.dm_db_missing_index_groups AS DMIG
INNER JOIN sys.dm_db_missing_index_group_stats AS DMIGS
	ON DMIGS.group_handle = DMIG.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS DMID
	ON DMID.index_handle = DMIG.index_handle
ORDER BY 1 DESC