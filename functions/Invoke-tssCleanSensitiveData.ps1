function Invoke-tssCleanSensitiveData {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $PLSDatabase
    )

    $tsstoolspath = Split-Path -Path ((Get-Module -ListAvailable tsstools).path) -Parent
    $ScriptCleanData = Join-Path -Path $tsstoolspath -ChildPath "sqlscripts\xpo.clean_sensitive_data.sql"

    $ResultObj = [pscustomobject]@{
					            Instancia = $SqlDatabase.parent.name
					            BaseDatos = $SqlDatabase.name
                                ScriptLimpieza = $ScriptCleanData
				                }

    
    if (Test-Path -Path $ScriptCleanData) {
        if ($PSCmdlet.ShouldProcess($PLSDatabase,"Ejecutando script de limpieza de data sensible")) {
            $Startdate = Get-Date
            Invoke-Sqlcmd -ServerInstance $PLSDatabase.parent.name -Database $PLSDatabase.name -InputFile $ScriptCleanData -QueryTimeout 0
            $Enddate = Get-Date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "DuracionLimpiezaDataSensible" -Value $duracion -MemberType NoteProperty
        }
    }
    else {
        Write-Warning "No se encontro el script de limpieza de data sensible"
    }
       
    Write-Output $ResultObj

}