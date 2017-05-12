function Invoke-tssCleanSensitiveData {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $PLSDatabase
    )

    $tsstoolspath = Split-Path -Path ((Get-Module -ListAvailable tsstools).path) -Parent
    $ScriptCleanData = Join-Path -Path $tsstoolspath -ChildPath "sqlscripts\xpo.clean_sensitive_data.sql"
    if (Test-Path -Path $ScriptCleanData) {
        if ($PSCmdlet.ShouldProcess($PLSDatabase,"Ejecutando script de limpieza de data sensible")) {
            Invoke-Sqlcmd -ServerInstance $PLSDatabase.parent.name -Database $PLSDatabase.name -InputFile $ScriptCleanData
        }
    }
    else {
        Write-Warning "No se encontro el script de limpieza de data sensible"
    }
       

}