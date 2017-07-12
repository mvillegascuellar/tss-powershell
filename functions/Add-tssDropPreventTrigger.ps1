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
    [parameter(Mandatory = $true, ParameterSetName = ”FromInnerFx", Position = 0)]
    [object] $TSSDatabase,

    [parameter(Mandatory = $true, ParameterSetName = ”Direct", Position = 0)]
    [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string] $Environment,

    [parameter(Mandatory = $true, ParameterSetName = ”Direct", Position = 1)]
    [string[]] $SubEnvironments,

    [parameter(Mandatory = $true, ParameterSetName = ”Direct", Position = 2)]
    [Validateset('PLS', 'PLSPWB', 'PLSWEB', 'PLS_AUDIT', 'PLSCONFIG', 'PLSEDI', 'All')]
    [string] $DBType = 'All'
  )

  $tsstoolspath = Split-Path -Path ((Get-Module -ListAvailable tsstools).path) -Parent
  $ScriptDBTrigger = Join-Path -Path $tsstoolspath -ChildPath "sqlscripts\xpo.disable_ddl_database_trigger.sql"
  if (-not (Test-Path -Path $ScriptDBTrigger)) {
    Write-Error "No se encontro el script de creación de trigger para evitar operaciones DDL"
    break
  }
    
  if ($PSCmdlet.ParameterSetName -eq "Direct") {
    foreach ($SubEnvironment in $SubEnvironments) {
      if ($DBType -eq 'All') {
        $tssDBTypes = 'PLS', 'PLSPWB', 'PLSWEB', 'PLS_AUDIT', 'PLSCONFIG', 'PLSEDI'
      }
      else {
        $tssDBTypes = $DBType
      }

      foreach ($tssDBType in $tssDBTypes) {
        $TSSDatabase = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $tssDBType
        if ($PSCmdlet.ShouldProcess($TSSDatabase, "Creando trigger para evitar operaciones DDL")) {
          if ($TSSDatabase.triggers.Contains("disableDrop")) {
            $TSSDatabase.triggers["disableDrop"].Drop()
          }
          Invoke-Sqlcmd2 -ServerInstance $TSSDatabase.parent.name -Database $TSSDatabase.name -InputFile $ScriptDBTrigger -QueryTimeout 0
          $TSSDatabase.ExecuteNonQuery("ENABLE TRIGGER [disableDrop] ON DATABASE") | Out-Null
        }
      } # End foreach DBTypes
    } # End foreach subenvironments
  } # End If parameter Set "Direct"
  elseif ($PSCmdlet.ParameterSetName -eq "FromInnerFx") {
    if ($PSCmdlet.ShouldProcess($TSSDatabase, "Creando trigger para evitar operaciones DDL")) {
      if ($TSSDatabase.triggers.Contains("disableDrop")) {
        $TSSDatabase.triggers["disableDrop"].Drop()
      }
      Invoke-Sqlcmd2 -ServerInstance $TSSDatabase.parent.name -Database $TSSDatabase.name -InputFile $ScriptDBTrigger -QueryTimeout 0 
      $TSSDatabase.ExecuteNonQuery("ENABLE TRIGGER [disableDrop] ON DATABASE") | Out-Null
    }
  }

}