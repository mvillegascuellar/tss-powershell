function Copy-tssCDCConfig {

    [CmdletBinding(SupportsShouldProcess)]
    param (
    [parameter(Mandatory=$true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$SourceEnvironment,
    [parameter(Mandatory=$true)]
    [string]$SourceSubEnvironment,
    [parameter(Mandatory=$true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$TargetEnvironment,
    [parameter(Mandatory=$true)]
    [string]$TargetSubEnvironment,
    [parameter(Mandatory=$false)]
    [switch]$SkipWEB,
    [switch]$SkipPWB
    )
    
    $DBsArray = @()
    [string] $sqlCDCquery = "SELECT s.name as Schema_Name, tb.name AS Table_Name FROM sys.tables tb INNER JOIN sys.schemas s on s.schema_id = tb.schema_id WHERE tb.is_tracked_by_cdc = 1"

    Write-Verbose "Preparando conexión a PLS"
    $SourcePLSDB = Get-tssDatabase -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLS'
    $TargetPLSDB = Get-tssDatabase -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLS'

    $DBItem = new-object PSObject -Property @{
                                            SourceDB = $SourcePLSDB;
                                            TargetDB = $TargetPLSDB;
                                            TargetFG = 'PLSChangeDataCapture';
                                            }
    $DBsArray += $DBItem

    if ($SkipPWB -eq $false)
    {
        Write-Verbose "Preparando conexión a PWB"        
        $SourcePWBDB = Get-tssDatabase -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database PLSPWB
        $TargetPWBDB = Get-tssDatabase -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database PLSPWB
        
        $DBItem = new-object PSObject -Property @{
                                                SourceDB = $SourcePWBDB;
                                                TargetDB = $TargetPWBDB;
                                                TargetFG = 'PacerPricingChangeDataCapture';
                                                }
        $DBsArray += $DBItem
    } 

    if ($SkipWEB -eq $false)
    {
        Write-Verbose "Preparando conexión a WEB"
        $SourcePWBDB = Get-tssDatabase -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database PLSWEB
        $TargetPWBDB = Get-tssDatabase -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database PLSWEB
        
        $DBItem = new-object PSObject -Property @{
                                                SourceDB = $SourcePWBDB;
                                                TargetDB = $TargetPWBDB;
                                                TargetFG = 'PRIMARY';
                                                }
        $DBsArray += $DBItem
    }
    
    foreach ($DBItem in $DBsArray)
    {
        $TargetDB = $DBItem.TargetDB
        $SourceDB = $DBItem.SourceDB
        $TargetFG = $DBItem.TargetFG
        if ($PSCmdlet.ShouldProcess($TargetDB,"Habilitando CDC en base de datos")) {
            #Write-Verbose "================================================="
            #Write-Verbose "Habilitando CDC en base de datos $TargetDB"
            #Write-Verbose "================================================="
            $TargetDB.ExecuteNonQuery("EXECUTE sys.sp_cdc_enable_db;") | Out-Null

            $CDCTableNames = Invoke-Sqlcmd2 -ServerInstance $SourceDB.parent.Name -Database $SourceDB.name -Query $sqlCDCquery
            foreach ($CDCTableName in $CDCTableNames)
            {
                $fulltablename = $CDCTableName["Schema_Name"] + '.' + $CDCTableName["Table_Name"]
                $schemaname = $CDCTableName["Schema_Name"]
                $tablename = $CDCTableName["Table_Name"]
                if ($TargetDB.Tables.contains($tablename,$schemaname))
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
                    $TargetDB.ExecuteNonQuery($sqlCDC)
                }
                else
                {
                    Write-Warning "No se encontro tabla $fulltablename en la base de datos"
                }
            }
        }
    }
    
}