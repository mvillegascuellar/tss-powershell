function Copy-tssAssemblyPCMiler {

    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $SourceServerName,
    [parameter(Mandatory=$true)]
    [string] $SourceDBName,
    [parameter(Mandatory=$true)]
    [string] $DestServerName,
    [parameter(Mandatory=$true)]
    [string] $DestDBName
    )
    
    $IsPWB = $DestDBName.ToUpper().StartsWith("PLSPWB_")
    $sourceassemblies = @()
    $SourceServer = Connect-DbaSqlServer -SqlServer $SourceServerName
    $sourceassemblies = $SourceServer.Databases[$SourceDBName].Assemblies | Where-Object {$_.isSystemObject -eq $false -and $_.name -like "PCMiler*"} 
    $DestServer = Connect-DbaSqlServer -SqlServer $DestServerName
    $DestDB = $DestServer.Databases[$DestDBName]

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
    if ($DestDB.Trustworthy -eq $false)
    {
        Write-Warning "Configurando como Trustworthy la base de datos $DestDBName"
        $sql = "ALTER DATABASE $DestDBName SET TRUSTWORTHY ON"
	    try
	    {
		    $DestServer.ConnectionContext.ExecuteNonQuery($sql) | Out-Null
	    }
	    catch { Write-Exception $_ }
    }

    <#Verificar el owner de la base de datos destino es el sa#>
    if ($DestDB.Owner -ne "sa")
    {
        Write-Warning "Configurando usuario sa como owner de la base de datos $DestDBName"
	    try
	    {
		    $DestDB.SetOwner("sa")
            $DestDB.Alter()
	    }
	    catch { Write-Exception $_ }
    }

    Write-Verbose "Eliminando las funciones dependientes de PCMiler"

    if ($IsPWB)
        {$UserfxList = "PCMMiles","PCMDriverTime","PCMZipCode","PCMCityState","PCMSearchLocations","PCMIsValidLocation"}
    else 
        {$UserfxList = "PCMMiles","PCMDriverTime"}

    $UserfxObjs = $DestDB.UserDefinedFunctions | Where-Object {$_.schema -eq "dbo" -and $UserfxList -contains $_.name} 
    foreach ($ufx in $UserfxObjs)
    {
        if ($DestDB.UserDefinedFunctions.Contains($ufx.name))
        {
            try
	        {
                $DestDB.UserDefinedFunctions[$ufx.name].drop()
            }
	        catch { Write-Exception $_ }
        }
    }

    foreach ($assembly in $sourceassemblies | sort-object -Property Name -Descending)
    {
        try
	    {
            $AssemblyName = $assembly.name
            if ($DestDB.Assemblies.Name -contains $assembly.name)
	        {
		        Write-Verbose "Eliminando assembly $AssemblyName"
		        $DestDB.Assemblies[$assembly.name].Drop()
	        }
        }
	    catch { 
		    $_ 
		    continue
	    }
    }

    foreach ($assembly in $sourceassemblies)
    {
        try
	    {
            $AssemblyName = $assembly.name
            Write-Verbose "Creando assembly $AssemblyName"
            $DestDB.ExecuteNonQuery($assembly.Script()) | Out-Null  
        }
	    catch { 
		    $_ 
		    continue
	    } 
    }

    if ($IsPWB)
    {
        Write-Verbose "Creando funciones para PWB"
        Invoke-Sqlcmd -ServerInstance $DestServerName -Database $DestDBName -Query $PWBPCMilerFxs
    }
    else
    {
        Write-Verbose "Creando funciones para PLS"
        Invoke-Sqlcmd -ServerInstance $DestServerName -Database $DestDBName -Query $PLSPCMilerFxs
    }

}