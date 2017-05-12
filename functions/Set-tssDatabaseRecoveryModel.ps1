function Set-tssDatabaseRecoveryModel {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase,

        [parameter(Mandatory=$true)]
        [Validateset('Full','Simple')]
        [string] $RecoveryModel
    )

    #$Database = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $DBType
    
    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Cambiando modelo de recuperación a $RecoveryModel")) {
        $SqlDatabase.RecoveryModel = $RecoveryModel
        $SqlDatabase.Alter()
    }
}
<#
Set-tssDatabaseRecoveryModel -Environment LOCAL -SubEnvironment DEV -DBType PLS -RecoveryModel Full -whatif
Get-DbaDatabase -SqlInstance localhost -Databases PLS_LOCAL_DEV
Set-tssDatabaseRecoveryModel -Environment LOCAL -SubEnvironment DEV -DBType PLS -RecoveryModel Simple -verbose
#>