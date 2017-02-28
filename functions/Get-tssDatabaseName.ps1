function Get-tssDatabaseName {
    
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment,
    [parameter(Mandatory=$true)]
    [string] $Database
    )

    [string]$FullDatabaseName = '';
    
    if (($SubEnvironment -eq "MAIN" -or $SubEnvironment -eq "HOTFIX") -and (($Environment -eq 'INT') -or ($Environment -eq 'QA') -or ($Environment -eq 'UAT')))
        { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }
    elseif ($Environment -eq 'PERF')
        { $FullDatabaseName = $Database + "_" + $Environment }
    elseif ($Environment -eq 'PROD')
        { $FullDatabaseName = $Database + "_PRD" }
    else { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }

    return $FullDatabaseName;

}