function Invoke-tssPrepareNewEnv {

  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [string]$SourceEnvironment,
    
    [parameter(Mandatory = $true)]
    [string]$SourceSubEnvironment,

    [parameter(Mandatory = $true)]
    [string]$TargetSubEnvironment,

    [parameter(Mandatory = $false)]
    [string]$NewAuditParentDB,

    [parameter(Mandatory = $false)]
    [switch]$SkipWEB,

    [parameter(Mandatory = $false)]
    [switch]$SkipPWB,

    [parameter(Mandatory = $false)]
    [switch]$UsePLSKeepSafe
  )

  
  Write-Verbose "Copiando CDC"
  Copy-tssCDCConfig -SourceEnvironment $SourceEnvironment -SourceSubEnvironment $SourceSubEnvironment -TargetEnvironment $SourceEnvironment -TargetSubEnvironment $TargetSubEnvironment 

  Write-Verbose "Copiando Sinonimos"
  Copy-tssSynonyms -SourceEnvironment $SourceEnvironment -SourceSubEnvironment $SourceSubEnvironment -TargetSubEnvironment $TargetSubEnvironment -NewParentDB $NewAuditParentDB 

  Write-Verbose "Copiando Configuraciones"
  if ($UsePLSKeepSafe) {
    Copy-tssPLSApplicationSettings -Environment $SourceEnvironment -UsePLSKeepSafe -DestSubEnvironment $TargetSubEnvironment 
  }
  else {
    Copy-tssPLSApplicationSettings -Environment $SourceEnvironment -SourceSubEnvironment $SourceSubEnvironment -DestSubEnvironment $TargetSubEnvironment 
  }
  
  Write-Verbose "Agregando usuarios de aplicacion"
  Add-tssPLSApplicationUsers -Environment $SourceEnvironment -SubEnvironment $TargetSubEnvironment

  Write-Verbose "Configurando usuarios de la instancia"
  Set-tssLoginPermissions -Environment $SourceEnvironment -SubEnvironment $TargetSubEnvironment -RODatabases PLS
  if ($SkipPWB -eq $false) {
    Set-tssLoginPermissions -Environment $SourceEnvironment -SubEnvironment $TargetSubEnvironment -RODatabases PLSPWB
  }
  if ($SkipWEB -eq $false) {
    Set-tssLoginPermissions -Environment $SourceEnvironment -SubEnvironment $TargetSubEnvironment -RODatabases PLSWEB
  }
  
  #Write-Verbose "Actualizando dlls de PCMiler"
  #Copy-tssAssemblyPCMiler -SourceEnvironment $SourceEnvironment -SourceSubEnvironment $SourceEnvironment -DestSubEnvironment $TargetSubEnvironment -SkipPWB $SkipPWB

}

#Invoke-tssPrepareNewEnv -SourceEnvironment DEV -SourceSubEnvironment UAT -TargetSubEnvironment DEV1 -NewAuditParentDB PLS_AUDIT_DEV_DEV1 -Verbose