$SourceServerName = "mvillegas"
$SourceDBName = "PLS_PRD"
$DestServerName = "mvillegas"
$DestDBName = "PLSPwb_INT_MAIN"

$IsPWB = $DestDBName.ToUpper().StartsWith("PLSPWB_")
$scriptpath = "D:\GitHub\tss-powershell\tss-CopyAssembly\"
$sourceassemblies = @()
$SourceServer = Connect-DbaSqlServer -SqlServer $SourceServerName
$sourceassemblies = $SourceServer.Databases[$SourceDBName].Assemblies | Where-Object {$_.isSystemObject -eq $false -and $_.name -like "PCMiler*"} 
$DestServer = Connect-DbaSqlServer -SqlServer $DestServerName
$DestDB = $DestServer.Databases[$DestDBName]

Write-Output "Iniciando verificación de configuraciones de base de datos"

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

Write-Output "Eliminando las funciones dependientes de PCMiler"

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
		    Write-Output "Eliminando assembly $AssemblyName"
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
        Write-Output "Creando assembly $AssemblyName"
        $DestDB.ExecuteNonQuery($assembly.Script()) | Out-Null  
    }
	catch { 
		$_ 
		continue
	} 
}

if ($IsPWB)
{
    Write-Output "Creando funciones para PWB"
    Invoke-Sqlcmd -ServerInstance $DestServerName -Database $DestDBName -InputFile "$scriptpath\PLSPWB.CreatePCMilerFunctions.sql"
}
else
{
    Write-Output "Creando funciones para PLS"
    Invoke-Sqlcmd -ServerInstance $DestServerName -Database $DestDBName -InputFile "$scriptpath\PLS.CreatePCMilerFunctions.sql"
}

