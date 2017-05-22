<#
.SYNOPSIS
Permite agregar el trigger que protege a las bases de datos de eliminaciones y creaciones de objetos por parte de los programadores.

.DESCRIPTION
Agrega un trigger a nivel de base de datos que evita la creaciónn y eliminación de objetos por parte del usuario "tssuser", el cual
es utilizado por los programadores. Este trigger normalmente solo debe estar presente en las bases de datos de desarrollo.

.PARAMETER TSSDatabase
Objeto de tipo Database al cual se le agregara el trigger. Pertenece al Parameter Set "FromInnerFx".

.PARAMETER Environment
Ambiente donde se encuentra la base de datos a la cual se agregara el trigger.  Pertenece al Parameter Set "Direct".

.PARAMETER SubEnvironment
Sub-Ambiente donde se encuentra la base de datos a la cual se agregara el trigger.  Pertenece al Parameter Set "Direct".

.PARAMETER DBType
Tipo de base de datos a la cual se agregara el trigger, sólo acepta valores PLS y PWB.  Pertenece al Parameter Set "Direct".

.EXAMPLE
An example

.NOTES
General notes
#>
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