GO
ALTER LOGIN [JXP024] WITH DEFAULT_DATABASE=[master]
GO
USE [master]
GO
ALTER LOGIN [JXP024] WITH PASSWORD=N'NewPassword' MUST_CHANGE
GO