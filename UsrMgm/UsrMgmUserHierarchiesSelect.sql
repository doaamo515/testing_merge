USE [CS_Multitenancy_3]
GO
/****** Object:  StoredProcedure [dbo].[UsrMgmUserHierarchiesSelect]    Script Date: 4/20/2022 1:20:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[UsrMgmUserHierarchiesSelect]
(
	 @UserId					BIGINT
	,@UserName					NVARCHAR(500)
	,@ApplicationTenantLinkId	BIGINT
	,@LCID						INT = 1033
	,@TotalRecords              INT = 0 OUTPUT
	,@ErrorCode		        	NVARCHAR(100) = '0' OUTPUT
)
AS
BEGIN
SET NOCOUNT ON 

-- Start: Declaration part starts here
	SET @ErrorCode ='0'
	SET @TotalRecords =0

	CREATE TABLE #TempHierarchies
	(
		 intIndex		INT IDENTITY(1,1)
		,HierarchyId	BIGINT
		,HierarchyName	NVARCHAR(MAX)
		,ParentId		BIGINT
		,CompanyId		INT
		,LevelNo		BIGINT
		,Status			BIT
	)


-- End: Declaration part ends here

/*
SELECT [HierarchyId] 
       ,[HierarchyId] as Id
      ,[Description] as HierarchyName
      ,[ParentId]
      ,[CompanyId]
      ,[CompanyLevelId] as LevelNo
      , Convert(bit,1) as [status]
FROM [Mst].[Hierarchies]


select * from Mst.Hierarchies
select * from Mst.CompanyLevels
*/

	IF NOT EXISTS(SELECT 1 FROM UsrMgm.Users U  WHERE U.UserId = @UserId AND U.UserName = @UserName AND U.ApplicationTenantLinkId = @ApplicationTenantLinkId)-- Added ApplicationTenantLinkId by Doaa on 19April2022
	BEGIN
		SET @ErrorCode = 'UM0001'
		RETURN
	END			  

	-- Start: CompanyLevelId = 1: LOB
	INSERT INTO #TempHierarchies
	(
		 HierarchyId	
		,HierarchyName	
		,ParentId		
		,CompanyId		
		,LevelNo		
		,Status			
	)
	SELECT 
			 H.HierarchyId
			,L.LOBName
			,H.ParentId
			,H.CompanyId
			,H.CompanyLevelId
			,0
	FROM Mst.LOBs L
	INNER JOIN Mst.Hierarchies H ON H.ReferenceLevelId = L.LOBId AND H.ApplicationTenantLinkId = L.ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
	WHERE H.CompanyLevelId = 1
	AND L.ApplicationTenantLinkId = @ApplicationTenantLinkId
	AND L.IsActive = 1
	AND L.IsDeleted = 0
	-- End: CompanyLevelId = 1: LOB

	-- Start: CompanyLevelId = 2: Markets
	INSERT INTO #TempHierarchies
	(
		 HierarchyId	
		,HierarchyName	
		,ParentId		
		,CompanyId		
		,LevelNo		
		,Status			
	)
	SELECT 
			 H.HierarchyId
			,L.MarketName
			,H.ParentId
			,H.CompanyId
			,H.CompanyLevelId
			,0
	FROM Mst.Markets L
	INNER JOIN Mst.Hierarchies H ON H.ReferenceLevelId = L.MarketId AND H.ApplicationTenantLinkId = L.ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
	WHERE H.CompanyLevelId = 2
	AND L.ApplicationTenantLinkId = @ApplicationTenantLinkId
	AND L.IsActive = 1
	AND L.IsDeleted = 0
	-- End: CompanyLevelId = 2: Markets


	-- Start: CompanyLevelId = 3: Accounts
	INSERT INTO #TempHierarchies
	(
		 HierarchyId	
		,HierarchyName	
		,ParentId		
		,CompanyId		
		,LevelNo		
		,Status			
	)
	SELECT 
			 H.HierarchyId
			,L.AccountName
			,H.ParentId
			,H.CompanyId
			,H.CompanyLevelId
			,0
	FROM Mst.Accounts L
	INNER JOIN Mst.Hierarchies H ON H.ReferenceLevelId = L.AccountId AND H.ApplicationTenantLinkId = L.ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
	WHERE H.CompanyLevelId = 3
	AND L.ApplicationTenantLinkId = @ApplicationTenantLinkId
	AND L.IsActive = 1
	AND L.IsDeleted = 0
	-- End: CompanyLevelId = 3: Accounts

	-- Start: CompanyLevelId = 4: Locations
	INSERT INTO #TempHierarchies
	(
		 HierarchyId	
		,HierarchyName	
		,ParentId		
		,CompanyId		
		,LevelNo		
		,Status			
	)
	SELECT 
			 H.HierarchyId
			,L.LocationName
			,H.ParentId
			,H.CompanyId
			,H.CompanyLevelId
			,0
	FROM Mst.Locations L
	INNER JOIN Mst.Hierarchies H ON H.ReferenceLevelId = L.LocationId AND H.ApplicationTenantLinkId = L.ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
	WHERE H.CompanyLevelId = 4
	AND L.ApplicationTenantLinkId = @ApplicationTenantLinkId
	AND L.IsActive = 1
	AND L.IsDeleted = 0
	-- End: CompanyLevelId = 4: Locations


	UPDATE TT  SET Status = 1
	FROM #TempHierarchies TT
	INNER JOIN Mst.UserHierarchyAccess UHA ON UHA.HierarchyId = TT.HierarchyId
	WHERE UHA.UserId = @UserId 

	SELECT 
	     HierarchyId
		,HierarchyId	AS Id
		,HierarchyName	
		,ParentId		
		,CompanyId		
		,LevelNo		
		,Status			
	FROM #TempHierarchies


-----Drop Temporary Table---------
     DROP TABLE #TempHierarchies
     
SET NOCOUNT OFF
END

