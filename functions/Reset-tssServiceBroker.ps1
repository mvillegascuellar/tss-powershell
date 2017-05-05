function Reset-tssServiceBroker
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL')]
    [parameter(Mandatory=$true)]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment,
    [switch] $SkipPWB
    )

    Write-Verbose "Preparando conexión a base de datos PLS"
    $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database 'PLS'

    if ($SkipPWB -eq $false){
        Write-Verbose "Preparando conexión a base de datos PWB"
        $PWBDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database 'PLSPWB'
    }
    
    [string]$AlterDBBroker = 'ALTER DATABASE CURRENT SET NEW_BROKER WITH ROLLBACK IMMEDIATE'
    
    if ($PSCmdlet.ShouldProcess($PLSDB,"Inicializando Serivice Broker")) {
        $PLSDB.ExecuteNonQuery($AlterDBBroker) | Out-Null
    }

    if ($SkipPWB -eq $false){
        if ($PSCmdlet.ShouldProcess($PWBDB,"Inicializando Serivice Broker")) {
            $PWBDB.ExecuteNonQuery($AlterDBBroker) | Out-Null
        }
    }
        
    $delsql = "DELETE FROM es.ServiceBrokerConversations;"
    
    if ($PSCmdlet.ShouldProcess($PLSDB,"Limpiando tabla es.ServiceBrokerConversations")) {
        $PLSDB.ExecuteNonQuery($delsql) | Out-Null
    }
}