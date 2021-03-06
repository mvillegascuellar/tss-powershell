﻿function Get-tssDatabase {
    
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment,
    [parameter(Mandatory=$true)]
    [Validateset('PLS', 'PLSPWB', 'PLSWEB', 'PLS_AUDIT', 'PLSCONFIG','PLSEDI')]
    [string] $Database
    )

    [string] $FullDatabaseName = ''
  
    if  ($Environment -eq 'PERF')
        { $FullDatabaseName = $Database + "_" + $Environment }
    elseif ($Environment -eq 'PROD')
        { $FullDatabaseName = $Database + "_PRD" }
    elseif ($Environment -eq 'DEVXPO')
        { $FullDatabaseName = $Database + "_DEV_" + $SubEnvironment }
    else { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }

    $DBServer = Get-tssConnection -Environment $Environment
    if ($DBServer.databases.contains($FullDatabaseName))
    {
        $tssDB = $DBServer.databases | Where-Object Name -eq $FullDatabaseName
    }
    else
    {
        Write-Error -Message "Invalid Environment and Sub-Environment combination. No database $FullDatabaseName was found" 
    }

    Write-Output $tssDB

}