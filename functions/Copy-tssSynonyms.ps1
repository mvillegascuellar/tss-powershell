function Copy-tssSynonyms {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$SourceEnvironment,

    [parameter(Mandatory = $true)]
    [string]$SourceSubEnvironment,    

    [parameter(Mandatory = $true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$TargetEnvironment,

    [parameter(Mandatory = $true)]
    [string]$TargetSubEnvironment
  )

  Write-Verbose "Preparando conexión a base de datos PLS Origen"
  $SourcePLSDB = Get-tssDatabase -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLS'
  Write-Verbose "Preparando conexión a base de datos PLS Destino"
  $TargetPLSDB = Get-tssDatabase -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLS'

  Write-Verbose "*** Inicio de copia de Sinonimos ***"
  foreach ($Synonym in $SourcePLSDB.Synonyms) {
    $synonymName = $Synonym.name
    if ($PSCmdlet.ShouldProcess($TargetPLSDB,"Copiando sinonimo $synonymName")) {
        if ($TargetPLSDB.Synonyms.contains($synonymName)) {
          $TargetPLSDB.Synonyms[$synonymName].drop()
        }
        $TargetPLSDB.ExecuteNonQuery($Synonym.script()) 
    }
  }
  Write-Verbose "*** Fin de copia de Sinonimos ***"

}