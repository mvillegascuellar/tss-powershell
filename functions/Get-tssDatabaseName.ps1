function Get-tssDatabaseName {
    
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [object] $SQLServer,
    [parameter(Mandatory=$true)]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment,
    [parameter(Mandatory=$true)]
    [string] $Database,
    [string] $DBSufix
    )

    [string]$FullDatabaseName = '';
    
    if (($SubEnvironment -eq "MAIN" -or $SubEnvironment -eq "HOTFIX") -and (($Environment -eq 'INT') -or ($Environment -eq 'QA') -or ($Environment -eq 'UAT')))
        { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }
    elseif ($Environment -eq 'PERF')
        { $FullDatabaseName = $Database + "_" + $Environment }
    elseif ($Environment -eq 'PROD')
        { $FullDatabaseName = $Database + "_PRD" }
    else { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }

    if ($DBSufix -ne $null -and $DBSufix.Trim() -ne '')
    {$FullDatabaseName = $FullDatabaseName  + "_" + $DBSufix}

    foreach ($db in $SQLServer.databases)
    {
        if ($db.name -eq $FullDatabaseName) {return $FullDatabaseName}
    }
    
    return $null;

}