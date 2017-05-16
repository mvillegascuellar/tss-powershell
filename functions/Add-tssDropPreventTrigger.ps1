function Add-tssDropPreventTrigger {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true, ParameterSetName=”FromInnerFx", Position=0)]
        [object] $TSSDatabase,

        [parameter(Mandatory=$true, ParameterSetName=”Direct", Position=0)]
        [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [string] $Environment,

        [parameter(Mandatory=$true, ParameterSetName=”Direct", Position=1)]
        [string] $SubEnvironment,

        [parameter(Mandatory=$true, ParameterSetName=”Direct", Position=2)]
        [Validateset('PLS','PWB')]
        [string] $DBType
    )

    if ($PSCmdlet.ParameterSetName -eq "Direct") {
        $TSSDatabase = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $DBType
    }

    $tsstoolspath = Split-Path -Path ((Get-Module -ListAvailable tsstools).path) -Parent
    $ScriptDBTrigger = Join-Path -Path $tsstoolspath -ChildPath "sqlscripts\xpo.disable_ddl_database_trigger.sql"
    if (Test-Path -Path $ScriptDBTrigger) {
        if ($PSCmdlet.ShouldProcess($TSSDatabase,"Creando trigger para evitar operaciones DDL")) {
            Invoke-Sqlcmd -ServerInstance $TSSDatabase.parent.name -Database $TSSDatabase.name -InputFile $ScriptDBTrigger -QueryTimeout 0
        }
    }
    else {
        Write-Warning "No se encontro el script de creación de trigger para evitar operaciones DDL"
    }

}