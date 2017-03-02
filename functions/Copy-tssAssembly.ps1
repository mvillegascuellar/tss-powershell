function Copy-tssAssemblyPCMiler {

    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $SourceEnvironment,
    [parameter(Mandatory=$true)]
    [string] $SourceSubEnvironment,
    [parameter(Mandatory=$true)]
    [string] $DestEnvironment,
    [parameter(Mandatory=$true)]
    [string] $DestSubEnvironment
    )
    
    
    $sourceassemblies = @()
    $SourceServer = Get-tssConnection -Environment $SourceEnvironment
    [string]$SourcePWBDB = Get-tssDatabaseName -SQLServer $SourceServer -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database PLSPWB
    $DestServer = Get-tssConnection -Environment $DestEnvironment
    [string]$DestPLSDB = Get-tssDatabaseName -SQLServer $DestServer -Environment $DestEnvironment -SubEnvironment $DestSubEnvironment -Database PLS
    [string]$DestPWBDB = Get-tssDatabaseName -SQLServer $DestServer -Environment $DestEnvironment -SubEnvironment $DestSubEnvironment -Database PLSPWB

    if ($SourcePWBDB -eq $null -or $SourcePWBDB.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PWB del Origen";
        return $null
    }
    if ($DestPLSDB -eq $null -or $DestPLSDB.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PLS del Destino"
        return $null
    }
    if ($DestPWBDB -eq $null -or $DestPWBDB.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PWB del Destino"
        return $null
    }


    $sourceassemblies = $SourceServer.databases[$SourcePWBDB].Assemblies | Where-Object {$_.isSystemObject -eq $false -and $_.name -like "PCMiler*"} 

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
    <#Verificar si la base de datos destino es trustworthy#>
    if ($DestServer.databases[$DestPLSDB].Trustworthy -eq $false)
    {
        Write-Warning "Configurando como Trustworthy la base de datos $DestPLSDB"
        $sql = "ALTER DATABASE $DestPLSDB SET TRUSTWORTHY ON"
	    try
	    {
		    $DestServer.ConnectionContext.ExecuteNonQuery($sql) | Out-Null
	    }
	    catch { Write-Error $_ }
    }
    if ($DestServer.databases[$DestPWBDB].Trustworthy -eq $false)
    {
        Write-Warning "Configurando como Trustworthy la base de datos $DestPWBDB"
        $sql = "ALTER DATABASE $DestPWBDB SET TRUSTWORTHY ON"
	    try
	    {
		    $DestServer.ConnectionContext.ExecuteNonQuery($sql) | Out-Null
	    }
	    catch { Write-Error $_ }
    } 

    <#Verificar el owner de la base de datos destino es el sa#>
    if ($DestServer.databases[$DestPLSDB].Owner -ne "sa")
    {
        Write-Warning "Configurando usuario sa como owner de la base de datos $DestPLSDB"
	    try
	    {
		    $DestServer.databases[$DestPLSDB].SetOwner("sa")
            $DestServer.databases[$DestPLSDB].Alter()
	    }
	    catch { Write-Exception $_ }
    }
    if ($DestServer.databases[$DestPWBDB].Owner -ne "sa")
    {
        Write-Warning "Configurando usuario sa como owner de la base de datos $DestPWBDB"
	    try
	    {
		    $DestServer.databases[$DestPWBDB].SetOwner("sa")
            $DestServer.databases[$DestPWBDB].Alter()
	    }
	    catch { Write-Exception $_ }
    }
    
    Write-Verbose "Eliminando las funciones dependientes de PCMiler en $DestPLSDB"   
    $UserfxList = "PCMMiles","PCMDriverTime","PCMZipCode","PCMCityState","PCMSearchLocations","PCMIsValidLocation"
    $UserfxObjs = $DestServer.databases[$DestPLSDB].UserDefinedFunctions | Where-Object {$_.schema -eq "dbo" -and $UserfxList -contains $_.name}
    foreach ($ufx in $UserfxObjs)
    {
        if ($DestServer.databases[$DestPLSDB].UserDefinedFunctions.Contains($ufx.name))
        {
            try
	        {
                $DestServer.databases[$DestPLSDB].UserDefinedFunctions[$ufx.name].drop()
            }
	        catch { Write-Error $_ }
        }
    }
    Write-Verbose "Eliminando las funciones dependientes de PCMiler en $DestPWBDB"   
    $UserfxObjs = $DestServer.databases[$DestPWBDB].UserDefinedFunctions | Where-Object {$_.schema -eq "dbo" -and $UserfxList -contains $_.name}
    foreach ($ufx in $UserfxObjs)
    {
        if ($DestServer.databases[$DestPWBDB].UserDefinedFunctions.Contains($ufx.name))
        {
            try
	        {
                $DestServer.databases[$DestPWBDB].UserDefinedFunctions[$ufx.name].drop()
            }
	        catch { Write-Error $_ }
        }
    }


    foreach ($assembly in $sourceassemblies | sort-object -Property Name -Descending)
    {
        try
	    {
            $AssemblyName = $assembly.name
            if ($DestServer.databases[$DestPLSDB].Assemblies.Name -contains $assembly.name)
	        {
		        Write-Verbose "Eliminando assembly $AssemblyName en $DestPLSDB"
		        $DestServer.databases[$DestPLSDB].Assemblies[$AssemblyName].Drop()
	        }
            if ($DestServer.databases[$DestPWBDB].Assemblies.Name -contains $assembly.name)
	        {
		        Write-Verbose "Eliminando assembly $AssemblyName en $DestPWBDB"
		        $DestServer.databases[$DestPWBDB].Assemblies[$AssemblyName].Drop()
	        }
        }
	    catch { 
		    Write-Error $_ 
	    }
    }

    foreach ($assembly in $sourceassemblies)
    {
        try
	    {
            $AssemblyName = $assembly.name
            Write-Verbose "Creando assembly $AssemblyName para $DestPLSDB"
            $DestServer.databases[$DestPLSDB].ExecuteNonQuery($assembly.Script()) 
            Write-Verbose "Creando assembly $AssemblyName para $DestPWBDB"
            $DestServer.databases[$DestPWBDB].ExecuteNonQuery($assembly.Script()) 
        }
	    catch { 
		    Write-Error $_ 
	    } 
    }

    Write-Verbose "Creando funciones para PLS"
    Invoke-Sqlcmd -ServerInstance $DestServer -Database $DestPLSDB -Query $PLSPCMilerFxs
    
    Write-Verbose "Creando funciones para PWB"
    Invoke-Sqlcmd -ServerInstance $DestServer -Database $DestPWBDB -Query $PWBPCMilerFxs
 
}