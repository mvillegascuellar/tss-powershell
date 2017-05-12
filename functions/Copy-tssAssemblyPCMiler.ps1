function Copy-tssAssemblyPCMiler {

    [CmdletBinding(SupportsShouldProcess)]
    param (
    [parameter(Mandatory=$true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string] $SourceEnvironment,
    [parameter(Mandatory=$true)]
    [string] $SourceSubEnvironment,
    [parameter(Mandatory=$true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string] $DestEnvironment,
    [parameter(Mandatory=$true)]
    [string] $DestSubEnvironment,
    [switch] $SkipPWB
    )
    
    $UserfxList = "PCMMiles","PCMDriverTime","PCMZipCode","PCMCityState","PCMSearchLocations","PCMIsValidLocation"
    
    Write-Verbose "Preparando conexion a base de datos Origen PWB"
    $SourcePWBDB = Get-tssDatabase -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database PLSPWB
    
    Write-Verbose "Preparando conexion a base de datos Destino PLS"
    $DestPLSDB = Get-tssDatabase -Environment $DestEnvironment -SubEnvironment $DestSubEnvironment -Database PLS

    if ($SkipPWB -eq $false){
        Write-Verbose "Preparando conexion a base de datos Destino PWB"
        $DestPWBDB = Get-tssDatabase -Environment $DestEnvironment -SubEnvironment $DestSubEnvironment -Database PLSPWB
    }
    
    # $sourceassemblies = @() 
    # $sourceassemblies = $SourcePWBDB.Assemblies | Where-Object {$_.isSystemObject -eq $false -and $_.name -like "PCMiler*"}
    $sourceassemblies = 'PcMilerCLR' ,'PcMilerCLR.XmlSerializers' 

    #region Create Fx Scripts

    # =============================================
    # Create script for the PLS PCMiler Fuctions
    # =============================================
    [string] $PLSPCMilerFxs = "CREATE FUNCTION [dbo].[PCMMiles](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMMiles]
    GO
    EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=11 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PCMDriverTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [dbo].[PCMDriverTime]
    GO
    CREATE FUNCTION [dbo].[PCMDriverTime](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMDriverTime]
    GO
    "

    # =============================================
    # Create script for the PWB PCMiler Fuctions
    # =============================================
    [string] $PWBPCMilerFxs = "CREATE FUNCTION [dbo].[PCMMiles](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMMiles]
    GO
    EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=11 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMMiles'
    GO
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PCMDriverTime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [dbo].[PCMDriverTime]
    GO
    CREATE FUNCTION [dbo].[PCMDriverTime](@zip1 [nvarchar](4000), @zip2 [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMDriverTime]
    GO
    CREATE FUNCTION [dbo].[PCMZipCode](@cityst [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMZipCode]
    GO
    EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=35 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMZipCode'
    GO
    /****** Object:  UserDefinedFunction [dbo].[PCMCityState]    Script Date: 12/14/2010 13:24:36 ******/
    CREATE FUNCTION [dbo].[PCMCityState](@zip [nvarchar](4000))
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMCityState]
    GO
    EXEC sys.sp_addextendedproperty @name=N'AutoDeployed', @value=N'yes' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFile', @value=N'PcMiler.cs' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
    GO
    EXEC sys.sp_addextendedproperty @name=N'SqlAssemblyFileLine', @value=23 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'FUNCTION',@level1name=N'PCMCityState'
    GO
    CREATE FUNCTION [dbo].[PCMSearchLocations](@zipCode [nvarchar](4000), @cityState [nvarchar](4000), @searchMode [int])
    RETURNS [nvarchar](4000) WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMSearchLocations]
    GO
    CREATE FUNCTION [dbo].[PCMIsValidLocation](@zipCode [nvarchar](4000), @cityState [nvarchar](4000))
    RETURNS [bit] WITH EXECUTE AS CALLER
    AS 
    EXTERNAL NAME [PcMilerCLR].[UserDefinedFunctions].[PCMIsValidLocation]
    GO
    "
    #endregion


    Write-Verbose "Iniciando verificación de configuraciones de base de datos"
    if ($DestPLSDB.Trustworthy -eq $false) {
        if ($PSCmdlet.ShouldProcess($DestPLSDB,'Configurando como Trustworthy la base de datos')) {
            Write-Warning "Configurando como Trustworthy la base de datos $DestPLSDB"
            $sql = "ALTER DATABASE $DestPLSDB SET TRUSTWORTHY ON"
	        try {
		        $DestPLSDB.ExecuteNonQuery($sql) | Out-Null
	        }
	        catch { Write-Error $_ }
        }
    }
    if ($SkipPWB -eq $false){
        if ($DestPWBDB.Trustworthy -eq $false) {
            if ($PSCmdlet.ShouldProcess($DestPWBDB,'Configurando como Trustworthy la base de datos')) {
                Write-Warning "Configurando como Trustworthy la base de datos $DestPWBDB"
                $sql = "ALTER DATABASE $DestPWBDB SET TRUSTWORTHY ON"
	            try {
		            $DestPWBDB.ExecuteNonQuery($sql) | Out-Null
	            }
	            catch { Write-Error $_ }
            }
        } 
    }

    if ($DestPLSDB.Owner -ne "sa") {
        if ($PSCmdlet.ShouldProcess($DestPLSDB,'Configurando usuario sa como owner de la base de datos')) {
            Write-Warning "Configurando usuario sa como owner de la base de datos $DestPLSDB"
	        try {
		        $DestPLSDB.SetOwner("sa")
                $DestPLSDB.Alter()
	        }
	        catch { Write-Exception $_ }
        }
    }
    if ($SkipPWB -eq $false){
        if ($DestPWBDB.Owner -ne "sa") {
            if ($PSCmdlet.ShouldProcess($DestPWBDB,'Configurando usuario sa como owner de la base de datos')) {
                Write-Warning "Configurando usuario sa como owner de la base de datos $DestPWBDB"
	            try {
		            $DestPWBDB.SetOwner("sa")
                    $DestPWBDB.Alter()
	            }
	            catch { Write-Exception $_ }
            }
        }
    }
    
    if ($PSCmdlet.ShouldProcess($DestPLSDB,'Eliminando las funciones dependientes de PCMiler')) {  
        $UserfxObjs = $DestPLSDB.UserDefinedFunctions | Where-Object {$_.schema -eq "dbo" -and $UserfxList -contains $_.name}
        foreach ($ufx in $UserfxObjs) {
            try {
                #Invoke-Sqlcmd -ServerInstance $DestPLSDB.parent.name -Database $DestPLSDB.name -Query "DROP FUNCTION $ufx"
                $ufx.drop()
            }
	        catch { Write-Error $_ }
        }
    }
    if ($SkipPWB -eq $false) {
        if ($PSCmdlet.ShouldProcess($DestPWBDB,'Eliminando las funciones dependientes de PCMiler')) {
            $UserfxObjs = $DestPWBDB.UserDefinedFunctions | Where-Object {$_.schema -eq "dbo" -and $UserfxList -contains $_.name}
            foreach ($ufx in $UserfxObjs) {
                try {
                    #Invoke-Sqlcmd -ServerInstance $DestPWBDB.parent.name -Database $DestPWBDB.name -Query "DROP FUNCTION $ufx"
                    $ufx.drop()
                }
	            catch { Write-Error $_ }
            }
        }
    }


    $DBAssemblies = Get-tssDatabaseAssembly -Database $DestPLSDB -AssemblyNames $sourceassemblies
    foreach ($DBAssembly in $DBAssemblies | sort-object -Property Name -Descending) {
        if ($PSCmdlet.ShouldProcess($DestPLSDB,"Eliminando assembly $DBAssembly")) {
		    $DBAssembly.Drop()
        }
    }

    if ($SkipPWB -eq $false) {
        $DBAssemblies = Get-tssDatabaseAssembly -Database $DestPWBDB -AssemblyNames $sourceassemblies
        foreach ($DBAssembly in $DBAssemblies | sort-object -Property Name -Descending) {
            if ($PSCmdlet.ShouldProcess($DestPWBDB,"Eliminando assembly $DBAssembly")) {
		        $DBAssembly.Drop()
            }
        }
    }
    
    $DBAssemblies = Get-tssDatabaseAssembly -Database $SourcePWBDB -AssemblyNames $sourceassemblies
        foreach ($DBAssembly in $DBAssemblies) {
        
        
        if ($PSCmdlet.ShouldProcess($DestPLSDB,"Creando assembly $DBAssembly")) {
            $DestPLSDB.parent.databases[$DestPLSDB.name].ExecuteNonQuery($DBAssembly.Script()) 
        }
        
        if ($SkipPWB -eq $false) {
            if ($PSCmdlet.ShouldProcess($DestPWBDB,"Creando assembly $DBAssembly")) {
                $DestPWBDB.parent.databases[$DestPWBDB.name].ExecuteNonQuery($DBAssembly.Script()) 
            }
        }
        
    }
        
    if ($PSCmdlet.ShouldProcess($DestPLSDB,"Creando funciones para PLS")) {
        Invoke-Sqlcmd -ServerInstance $DestPLSDB.parent.name -Database $DestPLSDB.name -Query $PLSPCMilerFxs
    }
    
    if ($SkipPWB -eq $false) {
        if ($PSCmdlet.ShouldProcess($DestPWBDB,"Creando funciones para PWB")) {
            Invoke-Sqlcmd -ServerInstance $DestPWBDB.parent.name -Database $DestPWBDB.name -Query $PWBPCMilerFxs
        }
    }
    
 
}