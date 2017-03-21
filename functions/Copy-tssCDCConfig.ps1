function Copy-tssCDCConfig {

    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string]$SourceEnvironment,
    [parameter(Mandatory=$true)]
    [string]$SourceSubEnvironment,
    [parameter(Mandatory=$true)]
    [string]$TargetEnvironment,
    [parameter(Mandatory=$true)]
    [string]$TargetSubEnvironment,
    [parameter(Mandatory=$false)]
    [string]$TargetDBSufix,
    [switch]$SkipWEB,
    [switch]$SkipPWB
    )

    $DBsArray = @()
    $TargetDBServer = Get-tssConnection -Environment $TargetEnvironment
    $SourceDBServer = Get-tssConnection -Environment $SourceEnvironment
    [string] $sqlCDCquery = "SELECT s.name as Schema_Name, tb.name AS Table_Name FROM sys.tables tb INNER JOIN sys.schemas s on s.schema_id = tb.schema_id WHERE tb.is_tracked_by_cdc = 1"

    Write-Verbose "Preparando conexión a PLS"
    [string]$SourcePLSDBName = Get-tssDatabaseName -SQLServer $SourceDBServer -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLS'
    [string]$TargetPLSDBName = Get-tssDatabaseName -SQLServer $TargetDBServer -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLS' -DBSufix $TargetDBSufix
    if ($SourcePLSDBName -eq $null -or $SourcePLSDBName.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PLS del Origen";
        return $null
    }
    if ($TargetPLSDBName -eq $null -or $TargetPLSDBName.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PLS del Destino"
        return $null
    }
    $DBItem = new-object PSObject -Property @{
                                            SourceDB = $SourcePLSDBName;
                                            TargetDB = $TargetPLSDBName;
                                            TargetFG = 'PLSChangeDataCapture';
                                            }
    $DBsArray += $DBItem

    if ($SkipPWB -eq $false)
    {
        Write-Verbose "Preparando conexión a PWB"
        [string]$SourcePWBDBName = Get-tssDatabaseName -SQLServer $SourceDBServer -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLSPWB'
        [string]$TargetPWBDBName = Get-tssDatabaseName -SQLServer $TargetDBServer -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLSPWB' -DBSufix $TargetDBSufix
        if ($SourcePWBDBName -eq $null -or $SourcePWBDBName.Trim() -eq '')
        {
            Write-Error "No es posible conectar a la base de datos PWB del Origen";
            return $null
        }
        if ($TargetPWBDBName -eq $null -or $TargetPWBDBName.Trim() -eq '')
        {
            Write-Error "No es posible conectar a la base de datos PWB del Destino"
            return $null
        }
        $DBItem = new-object PSObject -Property @{
                                                SourceDB = $SourcePWBDBName;
                                                TargetDB = $TargetPWBDBName;
                                                TargetFG = 'PacerPricingChangeDataCapture';
                                                }
        $DBsArray += $DBItem
    } 

    if ($SkipWEB -eq $false)
    {
        Write-Verbose "Preparando conexión a WEB"
        [string]$SourceWEBDBName = Get-tssDatabaseName -SQLServer $SourceDBServer -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLSWEB'
        [string]$TargetWEBDBName = Get-tssDatabaseName -SQLServer $TargetDBServer -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLSWEB' -DBSufix $TargetDBSufix
        if ($SourceWEBDBName -eq $null -or $SourceWEBDBName.Trim() -eq '')
        {
            Write-Error "No es posible conectar a la base de datos WEB del Origen";
            return $null
        }
    
        if ($TargetWEBDBName -eq $null -or $TargetWEBDBName.Trim() -eq '')
        {
            Write-Error "No es posible conectar a la base de datos PWB del Destino"
            return $null
        }
        $DBItem = new-object PSObject -Property @{
                                                SourceDB = $SourceWEBDBName;
                                                TargetDB = $TargetWEBDBName;
                                                TargetFG = 'PRIMARY';
                                                }
        $DBsArray += $DBItem
    }
    
    foreach ($DBItem in $DBsArray)
    {
        $TargetDBName = $DBItem.TargetDB
        $SourceDBName = $DBItem.SourceDB
        $TargetFG = $DBItem.TargetFG
        Write-Verbose "================================================="
        Write-Verbose "Habilitando CDC en base de datos $TargetDBName"
        Write-Verbose "================================================="
        $TargetDBServer.Databases[$TargetDBName].ExecuteNonQuery("EXECUTE sys.sp_cdc_enable_db;") | Out-Null

        $CDCTableNames = Invoke-Sqlcmd2 -ServerInstance $SourceDBServer.Name -Database $SourceDBName -Query $sqlCDCquery
        foreach ($CDCTableName in $CDCTableNames)
        {
            $fulltablename = $CDCTableName["Schema_Name"] + '.' + $CDCTableName["Table_Name"]
            $schemaname = $CDCTableName["Schema_Name"]
            $tablename = $CDCTableName["Table_Name"]
            if ($TargetDBServer.Databases[$TargetDBName].Tables.contains($tablename,$schemaname))
            {
                Write-Verbose "Habilitando CDC en tabla $fulltablename"
                $sqlCDC = " EXEC sys.sp_cdc_disable_table
                            @source_schema = N'$schemaname'
                            , @source_name = N'$tablename'
                            , @capture_instance = N'all'
                            go
                    
                            EXECUTE sys.sp_cdc_enable_table
                            @source_schema = N'$schemaname'
                            , @source_name = N'$tablename'
                            , @role_name = N'cdc_Admin'
                            , @filegroup_name = N'$TargetFG'
                            , @supports_net_changes = 0
                            go"
                $TargetDBServer.Databases[$TargetDBName].ExecuteNonQuery($sqlCDC)
            }
            else
            {
                Write-Warning "No se encontro tabla $fulltablename en la base de datos"
            }
        }
    
    }
    
}