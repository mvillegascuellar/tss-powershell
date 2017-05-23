function Save-tssPLSApplicationSettings {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$Environment,
        
    [parameter(Mandatory = $true)]
    [string]$SourceSubEnvironment
  )

  Write-Verbose "Preparando conexión a Origen"
  $SourcePLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SourceSubEnvironment -Database PLS

  $SqlInstance = $SourcePLSDB.parent

  if (-not $SqlInstance.Databases.contains('PLSKeepSafe')) {
    if ($PSCmdlet.ShouldProcess($SqlInstance, "Creando la base de datos PLSKeepSafe")) {
      $KeepSafeDB = New-Object Microsoft.SqlServer.Management.Smo.Database($SqlInstance, "PLSKeepSafe")
      $KeepSafeDB.Create()
    }
  }
  
  $KeepSafeDB = $SqlInstance.Databases['PLSKeepSafe']
  
  $AppSettingTables = "ApplicationSetting",
                      "ApplicationSettingCompany",
                      "Printer",
                      "PLSUser",
                      "UserCompany",
                      "UserCompanyRole",
                      "role",
                      "Company"

  foreach ($AppSettingTable in $AppSettingTables) {
    if ($PSCmdlet.ShouldProcess($KeepSafeDB, "Copiando la tabla $AppSettingTable")) {
      Copy-tssTable -SourceDB $SourcePLSDB -SrcTable $AppSettingTable -TargetDB $KeepSafeDB -Truncate
    }
  }                      

}