function Set-tssDatabaseRecoveryModel {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase,

        [parameter(Mandatory=$true)]
        [Validateset('Full','Simple')]
        [string] $RecoveryModel
    )

    $ResultObj = [pscustomobject]@{Instancia = $SqlDatabase.parent.name
                                   BaseDatos = $SqlDatabase.name
                                   ModeloRecuperacionActual = $SqlDatabase.RecoveryModel
                                   ModeloRecuperacionNuevo = $RecoveryModel}
    
    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Cambiando modelo de recuperación a $RecoveryModel")) {
        if ($SqlDatabase.RecoveryModel -ne $RecoveryModel) {
            $ResultObj | Add-Member -Name "CambioRealizado" -Value $true -MemberType NoteProperty
            $Startdate = get-date
            $SqlDatabase.RecoveryModel = $RecoveryModel
            $SqlDatabase.Alter()
            $Enddate = get-date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "DuracionCambioModeloRecuperacion" -Value $duracion -MemberType NoteProperty
        }        
        else {
            $ResultObj | Add-Member -Name "CambioRealizado" -Value $false -MemberType NoteProperty
        }
    }

    Write-Output $ResultObj
}
<#
Set-tssDatabaseRecoveryModel -Environment LOCAL -SubEnvironment DEV -DBType PLS -RecoveryModel Full -whatif
Get-DbaDatabase -SqlInstance localhost -Databases PLS_LOCAL_DEV
Set-tssDatabaseRecoveryModel -Environment LOCAL -SubEnvironment DEV -DBType PLS -RecoveryModel Simple -verbose
#>