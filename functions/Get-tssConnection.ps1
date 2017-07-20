function Get-tssConnection {
    
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $Environment
    )

    $ServerName = ''
    
    if ($Environment -eq 'INT') { $ServerName = 'ROSQLDEV01.devxpo.pvt' }
    elseif ($Environment -eq 'QA') { $ServerName = 'rosqlqa01.qaxpo.pvt' }
    elseif ($Environment -eq 'UAT') { $ServerName = 'rosqluat01.uatxpo.pvt' }
    elseif ($Environment -eq 'PERF') { $ServerName = 'ROSQLPERF1.qaxpo.pvt' }
    elseif ($Environment -eq 'PROD') { $ServerName = 'RODBPRDSCL02.xpo.pvt' }
    elseif ($Environment -eq 'DEV') { $ServerName = 'tssplsdb.tss.com.pe' }
    elseif ($Environment -eq 'LOCAL') { $ServerName = 'mvillegas.tss.com.pe' }
    elseif ($Environment -eq 'DBA') { $ServerName = 'devsqlstage01.xpo.pvt' }
    elseif ($Environment -eq 'DEVXPO') { $ServerName = 'IDDDW0413.devxpo.pvt' }
    else {Write-Error -Message "Invalid Environment." }

    $DBServer = Connect-DbaSqlServer -SqlServer $ServerName
    
    return $DBServer
}