function Add-tssPLSApplicationUsers {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$Environment,

    [parameter(Mandatory = $true)]
    [string]$SubEnvironment,

    [switch]$OutputScriptOnly

  )

  Write-Verbose "Preparando conexión a la base de datos"
  $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database PLS
   
  Write-Verbose "Preparando los usuarios a insertar"
  $Developers = New-Object -TypeName System.Collections.ArrayList
  $QAs = New-Object -TypeName System.Collections.ArrayList
  $Analysts = New-Object -TypeName System.Collections.ArrayList
  $InfoSys = New-Object -TypeName System.Collections.ArrayList

  $tsstoolspath = Split-Path -Path ((Get-Module tsstools).path) -Parent
  $DevelopersList = Join-Path -Path $tsstoolspath -ChildPath "config\developers.txt"
  $QAsList = Join-Path -Path $tsstoolspath -ChildPath "config\qas.txt"
  $AnalystsList = Join-Path -Path $tsstoolspath -ChildPath "config\analysts.txt"
  $InfosysList = Join-Path -Path $tsstoolspath -ChildPath "config\infosys.txt"

  # llenando el arreglo de developers
  foreach ($developer in (Get-Content -Path $DevelopersList)) {
    $Developers.Add($developer) | Out-Null   
  }

  # llenando el arreglo de $QAs
  foreach ($qa in (Get-Content -Path $QAsList)) {
    $QAs.Add($qa) | Out-Null   
  }
  
  # llenando el arreglo de $Analysts
  foreach ($analyst in (Get-Content -Path $AnalystsList)) {
    $Analysts.Add($analyst) | Out-Null   
  }
  
  # llenando el arreglo de $InfoSys
  foreach ($infoS in (Get-Content -Path $InfosysList)) {
    $InfoSys.Add($infoS) | Out-Null   
  }

  $UsersScript = "SET XACT_ABORT ON;
                    BEGIN TRANSACTION;

                    exec dbo.spuSystemIndexReset 'UserCompanyRole'

                    DECLARE 
                        @UserName VARCHAR(20),	  @FirstName VARCHAR(50),	@LastName VARCHAR(50), 
                        @CreationDate DATETIME,	  @UserId INT,				@UserCompanyId INT, 
                        @RoleId INT,			  @RoleAdminId INT,			@CompanyId INT, 
                        @UserCompanyRoleId INT,	  @CompanyCode VARCHAR(20),	@v_IsDefaultCompany CHAR(1)

                    SELECT @RoleId = RoleId
                    FROM role
                    WHERE Description LIKE 'APPLICATION/ACCESS ADMINISTRATION%'
                        AND Status = '1';

                    SELECT @RoleAdminId = RoleId
                    FROM role
                    WHERE Description LIKE 'APPLICATION ADMINISTRATION%'
                        AND Status = '1';

                    SET @FirstName = 'x';
                    SET @LastName = 'x';
                    SET @CreationDate = GETDATE()

                    DECLARE @x TABLE(username VARCHAR(64))
                    "
  if ($Environment -cin ('DEV', 'DEVXPO', 'INT')) {
    foreach ($developer in $Developers) {
      $UsersScript = $UsersScript + "INSERT INTO @x VALUES('" + $developer + "') `n"
    }
  }   
  if ($Environment -cin ('QA', 'INT', 'UAT')) {
    foreach ($qa in $QAs) {
      $UsersScript = $UsersScript + "INSERT INTO @x VALUES('" + $qa + "') `n"
    }
  }                 
  foreach ($analyst in $Analysts) {
    $UsersScript = $UsersScript + "INSERT INTO @x VALUES('" + $analyst + "') `n"
  }
  foreach ($InfoS in $InfoSys) {
    $UsersScript = $UsersScript + "INSERT INTO @x VALUES('" + $InfoS + "') `n"
  }

  $UsersScript = $UsersScript + "INSERT INTO @x VALUES('SVC_IISDEV1') `n"
  $UsersScript = $UsersScript + "INSERT INTO @x VALUES('SVC_IISQA1') `n"
  $UsersScript = $UsersScript + "INSERT INTO @x VALUES('plsediadmin') `n"

  $UsersScript = $UsersScript + "DECLARE xCursor CURSOR
    FOR SELECT username FROM @x;
    OPEN xCursor;
    FETCH NEXT FROM xCursor INTO @username;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        
        IF  (
        SELECT COUNT(*)
        FROM PLSUser
        WHERE UserName = @UserName
        ) > 0
        BEGIN
        
        UPDATE	 P
            SET	 Status = '1',
                UpdatedBy = 'PLSBOADMIN',
                UpdateDate = GETDATE()
            FROM	 PLSUser P
            WHERE	 UserName = @UserName
                AND Status <> '1';


        SELECT @UserId = userID
        FROM PLSUser
        WHERE UserName = @UserName;

        
        IF NOT EXISTS   (
                        SELECT 1
                        FROM officeteamuser
                        WHERE UserId = @UserId
                        AND OfficeTeamId = 1
                        )
        BEGIN
            PRINT 'Inserting OfficeTeamUser: '
            INSERT INTO OfficeTeamUser
                (UserId
                ,OfficeTeamId
                ,CreatedBy
                ,CreationDate
                ,UpdatedBy
                ,UpdateDate
                ,AllowToSeeChildrenInformation
                ,IsDefault)
            VALUES
                (@UserId
                ,1
                ,'ADMIN'
                ,GETDATE()
                ,'ADMIN'
                ,GETDATE()
                ,'1'
                ,'1')
        END;

        DECLARE cur_Company CURSOR FOR SELECT companyid from Company
        OPEN cur_Company;
        FETCH NEXT FROM cur_Company INTO @CompanyId
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @CompanyId = 1 -- C010
                SET @v_IsDefaultCompany = '1'
            ELSE
                SET @v_IsDefaultCompany = '0'
        
            SET @UserCompanyId = NULL
            SELECT @UserCompanyId = UserCompanyId
            FROM UserCompany
            WHERE UserId = @UserId
                    AND CompanyId = @CompanyId;
            IF ISNULL(@UserCompanyId, 0) = 0
                BEGIN
                    EXEC spuSystemIndexGetId
                        @TableName = N'UserCompany',
                        @Quantity = 1,
                        @Id = @UserCompanyId OUTPUT;
                    INSERT INTO dbo.UserCompany
                    (UserCompanyId,
                        CompanyId,
                        UserId,
                        IsDefaultCompany,
                        CreatedBy,
                        CreationDate,
                        UpdatedBy,
                        UpdateDate
                    )
                    VALUES
                    (@UserCompanyId,
                        @CompanyId,
                        @UserId,
                        @v_IsDefaultCompany,
                        'ADMIN',
                        GETDATE(),
                        'ADMIN',
                        GETDATE()
                    );
                END;
            SELECT @UserCompanyRoleId = UserCompanyRoleId
            FROM UserCompanyRole
            WHERE UserCompanyId = @UserCompanyId;
            IF(
                (
                    SELECT COUNT(*)
                    FROM UserCompanyRole
                    WHERE UserCompanyId = @UserCompanyId
                        AND RoleId = @RoleAdminId
                ) > 0)
                AND (
                    (
                        SELECT COUNT(*)
                        FROM UserCompanyRole
                        WHERE UserCompanyId = @UserCompanyId
                        AND RoleId = @RoleId
                    ) = 0)
                BEGIN
                    UPDATE dbo.UserCompanyRole
                        SET
                        RoleId = @RoleId,
                        UpdatedBy = 'PLSBOADMIN',
                        UpdateDate = GETDATE()
                    WHERE UserCompanyRoleId = @UserCompanyRoleId
                        AND RoleId = @RoleAdminId;
                END;
            ELSE
                BEGIN
                    IF(
                        (
                        SELECT COUNT(*)
                        FROM UserCompanyRole
                        WHERE UserCompanyId = @UserCompanyId
                            AND RoleId = @RoleId
                        ) = 0)
                        BEGIN
                        DECLARE @p3 INT;
                        EXEC spuSystemIndexGetId
                                @TableName = N'UserCompanyRole',
                                @Quantity = 1,
                                @Id = @p3 OUTPUT;
                        EXEC sp_executesql
                                N' INSERT INTO [UserCompanyRole] ( [UserCompanyRoleId], [UserCompanyId], [RoleId], [CreatedBy], 
                        [CreationDate], [UpdatedBy], [UpdateDate] )  VALUES  ( @UserCompanyRoleId, @UserCompanyId, @RoleId, @CreatedBy, 
                        @CreationDate, @UpdatedBy, @UpdateDate ) ',
                                N'@UserCompanyRoleId int,@UserCompanyId int,@RoleId int,@CreatedBy varchar(64),@CreationDate datetime2(7),
                        @UpdatedBy varchar(64),@UpdateDate datetime2(7)',
                                @UserCompanyRoleId = @p3,
                                @UserCompanyId = @UserCompanyId,
                                @RoleId = @RoleId,
                                @CreatedBy = 'PLSBOADMIN',
                                @CreationDate = @CreationDate,
                                @UpdatedBy = 'PLSBOADMIN',
                                @UpdateDate = @CreationDate;
                        END;
                    IF(
                        (
                        SELECT COUNT(*)
                        FROM UserCompanyRole
                        WHERE UserCompanyId = @UserCompanyId
                            AND RoleId = @RoleAdminId
                        ) = 0)
                        BEGIN
                        DECLARE @p6 INT;
                        EXEC spuSystemIndexGetId
                                @TableName = N'UserCompanyRole',
                                @Quantity = 1,
                                @Id = @p6 OUTPUT;
                        EXEC sp_executesql
                                N' INSERT INTO [UserCompanyRole] ( [UserCompanyRoleId], [UserCompanyId], [RoleId], [CreatedBy], 
                        [CreationDate], [UpdatedBy], [UpdateDate] )  VALUES  ( @UserCompanyRoleId, @UserCompanyId, @RoleId, @CreatedBy, 
                        @CreationDate, @UpdatedBy, @UpdateDate ) ',
                                N'@UserCompanyRoleId int,@UserCompanyId int,@RoleId int,@CreatedBy varchar(64),@CreationDate datetime2(7),
                        @UpdatedBy varchar(64),@UpdateDate datetime2(7)',
                                @UserCompanyRoleId = @p6,
                                @UserCompanyId = @UserCompanyId,
                                @RoleId = @RoleAdminId,
                                @CreatedBy = 'PLSBOADMIN',
                                @CreationDate = @CreationDate,
                                @UpdatedBy = 'PLSBOADMIN',
                                @UpdateDate = @CreationDate;
                        END;
                END;

            FETCH NEXT FROM cur_Company INTO @CompanyId
        END;
        CLOSE cur_Company;
        DEALLOCATE cur_Company;
        END;
        ELSE 
        BEGIN 
        declare @p1 int
        exec spuSystemIndexGetId @TableName=N'PlsUser',@Quantity=1,@Id=@p1 output

        exec sp_executesql N' INSERT INTO [PlsUser] ( [UserId], [FirstName], [LastName], [UserName], [Password], [Phone], 
        [Fax], [Email], [Title], [SecretQuestion], [SecretAnswer], [Style], [Culture], [DateFormat], [TimeFormat], [ReportToId], 
        [LoginNumTries], [HasToChangePassword], [IsBlocked], [IsSystemUser], [Status], [DefaultLanguage], [DefaultModule], 
        [CreatedBy], [CreationDate], [UpdatedBy], [UpdateDate] )  
        VALUES  ( @UserId, @FirstName, @LastName, @UserName, @Password, @Phone, @Fax, @Email, @Title, @SecretQuestion, 
        @SecretAnswer, @Style, @Culture, @DateFormat, @TimeFormat, @ReportToId, @LoginNumTries, @HasToChangePassword, 
        @IsBlocked, @IsSystemUser, @Status, @DefaultLanguage, @DefaultModule, @CreatedBy, @CreationDate, @UpdatedBy, 
        @UpdateDate ) ',
        N'@UserId int,@FirstName varchar(50),@LastName varchar(50),@UserName varchar(64),@Password varchar(100),@Phone varchar(20),
            @Fax varchar(20),@Email varchar(50),@Title varchar(20),@SecretQuestion varchar(100),@SecretAnswer varchar(100),
            @Style varchar(50),@Culture varchar(5),@DateFormat varchar(20),@TimeFormat varchar(20),@ReportToId int,@LoginNumTries int,
            @HasToChangePassword char(1),@IsBlocked char(1),@IsSystemUser char(1),@Status char(1),@DefaultLanguage varchar(10),
            @DefaultModule int,@CreatedBy varchar(64),@CreationDate datetime2(7),@UpdatedBy varchar(64),@UpdateDate datetime2(7)',
        @UserId=@p1,@FirstName=@FirstName,@LastName=@LastName,@UserName=@UserName,@Password=NULL,@Phone='6565656',@Fax='45454',
        @Email='PLSBOADMIN@TSS.COM.PE',@Title='Mr.',@SecretQuestion=NULL,@SecretAnswer=NULL,@Style=NULL,@Culture='en-US',
        @DateFormat='MM/dd/yyyy',@TimeFormat='HH:mm',@ReportToId=24,@LoginNumTries=NULL,@HasToChangePassword='0',@IsBlocked='0',
        @IsSystemUser='0',@Status='1',@DefaultLanguage=NULL,@DefaultModule=NULL,@CreatedBy='PLSBOADMIN',
        @CreationDate=@CreationDate,@UpdatedBy='PLSBOADMIN',@UpdateDate=@CreationDate

        exec sp_executesql N' INSERT INTO [OfficeTeamUser] ( UserId, OfficeTeamId, CreatedBy, CreationDate
        ,UpdatedBy, UpdateDate, AllowToSeeChildrenInformation, IsDefault )  VALUES  ( @UserId, @OfficeTeamId, @CreatedBy, 
        @CreationDate, @UpdatedBy, @UpdateDate, @AllowToSeeChildrenInformation, @IsDefault ) ',
        N'@UserId int, @OfficeTeamId int, @CreatedBy varchar(64), @CreationDate datetime2(7), @UpdatedBy varchar(64), 
        @UpdateDate datetime2(7), @AllowToSeeChildrenInformation char(1), @IsDefault char(1)',
        @UserId=@p1, @OfficeTeamId=1, @CreatedBy='PLSBOADMIN', @CreationDate=@CreationDate, 
        @UpdatedBy='PLSBOADMIN', @UpdateDate=@CreationDate, @AllowToSeeChildrenInformation='1', @IsDefault='1'

        DECLARE cur_Company CURSOR FOR SELECT companyid from Company
        OPEN cur_Company;
        FETCH NEXT FROM cur_Company INTO @CompanyId
        WHILE @@FETCH_STATUS = 0
        BEGIN

            IF @CompanyId = 1 -- C010
                SET @v_IsDefaultCompany = '1'
            ELSE
                SET @v_IsDefaultCompany = '0'

            declare @p2 int
            exec spuSystemIndexGetId @TableName=N'UserCompany',@Quantity=1,@Id=@p2 output
            exec sp_executesql N' INSERT INTO [UserCompany] ( [UserCompanyId], [UserId], [CompanyId], [IsDefaultCompany], 
            [CreatedBy], [CreationDate], [UpdatedBy], [UpdateDate] )  
            VALUES  ( @UserCompanyId, @UserId, @CompanyId, @IsDefaultCompany, @CreatedBy, @CreationDate, @UpdatedBy, @UpdateDate ) ',
            N'@UserCompanyId int,@UserId int,@CompanyId int,@IsDefaultCompany char(1),@CreatedBy varchar(64),@CreationDate datetime2(7),
                @UpdatedBy varchar(64),@UpdateDate datetime2(7)',
            @UserCompanyId=@p2,@UserId=@p1,@CompanyId=@CompanyId,@IsDefaultCompany=@v_IsDefaultCompany,@CreatedBy='PLSBOADMIN',
            @CreationDate=@CreationDate,@UpdatedBy='PLSBOADMIN',
            @UpdateDate=@CreationDate


            declare @p4 int
            exec spuSystemIndexGetId @TableName=N'UserCompanyRole',@Quantity=1,@Id=@p4 output
            exec sp_executesql N' INSERT INTO [UserCompanyRole] ( [UserCompanyRoleId], [UserCompanyId], [RoleId], [CreatedBy], 
            [CreationDate], [UpdatedBy], [UpdateDate] )  VALUES  ( @UserCompanyRoleId, @UserCompanyId, @RoleId, @CreatedBy, 
            @CreationDate, @UpdatedBy, @UpdateDate ) ',
            N'@UserCompanyRoleId int,@UserCompanyId int,@RoleId int,@CreatedBy varchar(64),@CreationDate datetime2(7),
                @UpdatedBy varchar(64),@UpdateDate datetime2(7)',
            @UserCompanyRoleId=@p4,@UserCompanyId=@p2,@RoleId=@RoleAdminId,@CreatedBy='PLSBOADMIN',
            @CreationDate=@CreationDate,@UpdatedBy='PLSBOADMIN',@UpdateDate=@CreationDate


            declare @p5 int
            exec spuSystemIndexGetId @TableName=N'UserCompanyRole',@Quantity=1,@Id=@p5 output	
            exec sp_executesql N' INSERT INTO [UserCompanyRole] ( [UserCompanyRoleId], [UserCompanyId], [RoleId], [CreatedBy], 
            [CreationDate], [UpdatedBy], [UpdateDate] )  VALUES  ( @UserCompanyRoleId, @UserCompanyId, @RoleId, @CreatedBy, 
            @CreationDate, @UpdatedBy, @UpdateDate ) ',
            N'@UserCompanyRoleId int,@UserCompanyId int,@RoleId int,@CreatedBy varchar(64),@CreationDate datetime2(7),
                @UpdatedBy varchar(64),@UpdateDate datetime2(7)',
            @UserCompanyRoleId=@p5,@UserCompanyId=@p2,@RoleId=@RoleId,@CreatedBy='PLSBOADMIN',
            @CreationDate=@CreationDate,@UpdatedBy='PLSBOADMIN',@UpdateDate=@CreationDate

            FETCH NEXT FROM cur_Company INTO @CompanyId			
        END;
        CLOSE cur_Company;
        DEALLOCATE cur_Company;
        END 
            
        FETCH NEXT FROM xCursor INTO @UserName;
    END;
    CLOSE xCursor;
    DEALLOCATE xCursor;
    COMMIT;
    GO"

  if ($OutputScriptOnly) {
    Write-Output $UsersScript
  }
  else {
    if ($PSCmdlet.ShouldProcess($PLSDB, 'Creando usuarios PLS')) {

      $PLSDB.ExecuteNonQuery($UsersScript)
      #ejecutamos el script una segunda vez para asegurar que pase bien
      #este es un bug conocido del script
      $PLSDB.ExecuteNonQuery($UsersScript)

    }
  }

}

