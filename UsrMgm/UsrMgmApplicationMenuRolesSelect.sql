USE [CS_Multitenancy_3]
GO
/****** Object:  StoredProcedure [dbo].[UsrMgmApplicationMenuRolesSelect]    Script Date: 4/20/2022 1:08:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[UsrMgmApplicationMenuRolesSelect]
(
	 @RoleId					NVARCHAR(MAX)
	,@IsActive					INT = NULL -- Active Changes
	,@ApplicationTenantLinkId	BIGINT
	,@LCID						INT = 1033
	,@ErrorCode		        	NVARCHAR(100) = '0' OUTPUT
)
AS
BEGIN
SET NOCOUNT ON 

-- Start: Variable declaration and assignment
	DECLARE
			 @SqlString				NVARCHAR(MAX)
			,@SqlActiveString		NVARCHAR(100)
			,@ApplicationMenuId		NVARCHAR(MAX)
			,@ApplicationMenuStr	NVARCHAR(MAX)
-- Variables for Logging Error Details
			,@ErrNumber				NVARCHAR(50)	
			,@ErrDescription		NVARCHAR(4000)	
			,@ErrState				INT				
			,@ErrSeverity			INT				
			,@ErrLine				INT				
			,@ErrTime				DATETIME
				
	CREATE TABLE #TempApplicationRoleMenus
	(
		 ApplicationMenuId	BIGINT
		,ApplicationMenuName NVARCHAR(MAX)
		,ParentId BIGINT
		,Level INT
		,RoleId	BIGINT
		,Position INT
		,Status BIT 
	)		

	IF (@IsActive IS NULL ) -- OR @IsActive = '')
		SET @SqlActiveString = ' ' 
	ELSE
		SET @SqlActiveString = ' AND IsActive = '+CAST(@IsActive AS VARCHAR(10))+''
	SET @RoleId	= REPLACE(@RoleId,'''','''''')	
	SET @RoleId = ISNULL(@RoleId,'')	

-- End: Variable declaration and assignment
  


	BEGIN TRY

			SET @SqlString = '
							WITH AppMenu AS (
							SELECT 
								  AM.ApplicationMenuId
								 ,AM.ApplicationMenuName
								 ,AM.ParentId
								 ,0 as LEVEL
								 ,'+@RoleId+' AS RoleId
								 ,AM.Position AS Position
								 ,0 AS Status
							FROM UsrMgm.ApplicationMenu	AM
							WHERE ParentId IS NULL 
							AND AM.ApplicationTenantLinkId = '+CAST(ISNULL(@ApplicationTenantLinkId,0) AS VARCHAR(100))+'
							AND AM.LCID = '+CAST(ISNULL(@LCID,0) AS VARCHAR(100))+
							@SqlActiveString +'
							AND AM.IsDeleted = 0  
							
							UNION ALL

							SELECT 
								  AM.ApplicationMenuId
								 ,AM.ApplicationMenuName
								 ,AM.ParentId
								 ,A.LEVEL+1 AS LEVEL
								 ,'+@RoleId+' AS RoleId
								 ,AM.Position AS Position
								 ,0 AS Status
							FROM UsrMgm.ApplicationMenu	AM
							INNER JOIN AppMenu A ON AM.ParentId = A.ApplicationMenuId
							WHERE AM.ApplicationTenantLinkId = '+CAST(ISNULL(@ApplicationTenantLinkId,0) AS VARCHAR(100))+'
							AND AM.ParentId IS NOT NULL 
							AND AM.LCID = '+CAST(ISNULL(@LCID,0) AS VARCHAR(100))+
							@SqlActiveString +'
							AND AM.IsDeleted = 0 
							
							)SELECT 
									 ApplicationMenuId As Id
									,ApplicationMenuName
									,ParentId
									,Level
									,RoleId
									,Position
									,Status
							 FROM AppMenu; 
						'
		
			PRINT @SqlString
			
			INSERT INTO #TempApplicationRoleMenus
			EXECUTE(@SqlString);		
						
			UPDATE TT SET TT.Status = 1 
			FROM #TempApplicationRoleMenus TT 
			INNER JOIN UsrMgm.ApplicationMenu AM ON AM.ApplicationMenuId = TT.ApplicationMenuId 
			INNER JOIN UsrMgm.ApplicationMenuRoles AMR ON AMR.ApplicationMenuId = AM.ApplicationMenuId AND AM.ApplicationTenantLinkId = AMR.ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
			WHERE AMR.RoleId IN (SELECT ITEMS FROM Split(@RoleId,',')) AND AMR.ApplicationTenantLinkId = @ApplicationTenantLinkId -- Added ApplicationTenantLinkId by Doaa on 19April2022
			
			SELECT 
				 ApplicationMenuId As Id
				,ApplicationMenuName
				,ParentId
				,Level as LevelNo
				,RoleId
				,Position
				,Status
			FROM #TempApplicationRoleMenus
			ORDER BY Position ASC
		
		SET @ErrorCode = '0'
		
		-----Drop Temporary Table---------
        DROP TABLE #TempApplicationRoleMenus
     
		
	END TRY

	BEGIN CATCH

				SET @ErrNumber				= ERROR_NUMBER()
				SET @ErrDescription			= ERROR_MESSAGE()
				SET @ErrState				= ERROR_STATE()
				SET @ErrSeverity			= ERROR_SEVERITY()
				SET @ErrLine				= ERROR_LINE()
				SET @ErrTime				= dbo.GetUtcDateTime()

 		EXEC [dbo].[CoreErrorLogInsert]	
				@ErrorNumber				= @ErrNumber
				,@ErrorDescription			= @ErrDescription
				,@ErrorProcedure       		= 'UsrMgmApplicationMenuRolesSelect'
				,@ErrorState				= @ErrState
				,@ErrorSeverity				= @ErrSeverity
				,@ErrorLine					= @ErrLine
				,@ErrorTime	                = @ErrTime


				   
		
		SET @ErrorCode = 'GN0001' -- Selection error

	END CATCH
	
SET NOCOUNT OFF
END

