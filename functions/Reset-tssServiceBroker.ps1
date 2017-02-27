function Reset-tssServiceBroker
{
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string] $Environment,
    [parameter(Mandatory=$true)]
    [string] $SubEnvironment
    )
    
    $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database "PLS"
    $PWBDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database "PLSPWB"

    $plssql = "ALTER DATABASE $PLSDB SET NEW_BROKER WITH ROLLBACK IMMEDIATE"
    $pwbsql = "ALTER DATABASE $PWBDB SET NEW_BROKER WITH ROLLBACK IMMEDIATE"

    Write-Verbose "Inicializando Serivice Broker para PLS"
    $PLSDB.parent.ConnectionContext.ExecuteNonQuery($plssql) | Out-Null
    Write-Verbose "Inicializando Serivice Broker para PWB"
    $PWBDB.parent.ConnectionContext.ExecuteNonQuery($pwbsql) | Out-Null

    $sql = "DELETE FROM $PLSDB.es.ServiceBrokerConversations;"
    
    Write-Verbose "Limpiando tabla es.ServiceBrokerConversations"
    $PLSDB.parent.ConnectionContext.ExecuteNonQuery($sql) | Out-Null
}