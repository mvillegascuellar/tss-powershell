function Get-tssDatabase {
    
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment,
    [parameter(Mandatory=$true)]
    [string] $Database
    )

    $FullDatabaseName = ''
    $tssDB
    
    if (($SubEnvironment -eq "MAIN" -or $SubEnvironment -eq "HOTFIX") -and (($Environment -eq 'INT') -or ($Environment -eq 'QA') -or ($Environment -eq 'UAT')))
        { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }
    elseif ($Environment -eq 'PERF')
        { $FullDatabaseName = $Database + "_" + $Environment }
    elseif ($Environment -eq 'PROD')
        { $FullDatabaseName = $Database + "_PRD" }
    else { $FullDatabaseName = $Database + "_" + $Environment + "_" + $SubEnvironment }

    $DBServer = Get-tssConnection -Environment $Environment
    if ($DBServer.databases.contains($FullDatabaseName))
    {
        $tssDB = $DBServer.databases[$FullDatabaseName]
    }
    else
    {
        Write-Error -Message "Invalid Environment and Sub-Environment combination." 
    }

    $tssDB

}