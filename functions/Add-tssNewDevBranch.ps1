function Add-tssNewDevBranch {
  
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [string] $VersionArchived,
    
    [parameter(Mandatory = $false)]
    [switch]$SkipRestore,

    [parameter(Mandatory = $false)]
    [switch]$SkipRename,

    [parameter(Mandatory = $false)]
    [switch]$SkipPreparation

  )

  $DevDBServer = 'MVILLEGAS'
  $MainBackupPath = 'D:\MSSQL\BACKUP\MVILLEGAS\'

  if (-not $SkipRestore) {
    try {
      Write-Verbose -Message "Eliminando bases de datos UAT_NEW"
      Find-DbaDatabase -SqlServer $DevDBServer -Pattern UAT_NEW | Invoke-tssNewBranchDropDBs
      Write-Verbose -Message "Eliminando bases de datos PRD_OLD"
      Find-DbaDatabase -SqlServer $DevDBServer -Pattern PRD_OLD | Invoke-tssNewBranchDropDBs 
      Write-Verbose -Message "Restaurando bases de datos UA_NEW"
      Restore-tssNewBranchDBs -VersionArchived $VersionArchived -DBServer $DevDBServer -MainBackupPath $MainBackupPath 
    }
    catch {
      return
    }
  }
  else {
    Write-Verbose "Esquivando el proceso de restauración"
  }

  if (-not $SkipRename) {
    try {
      Write-Verbose -Message "Renombrando las bases de datos"
      Invoke-tssNewBranchRenameDBs -DBServer $DevDBServer
    }
    catch {
      return
    }
  }
  else {
    Write-Verbose "Esquivando el proceso de renombrado"
  }

  if (-not $SkipPreparation) {

    Write-Verbose -Message "Preparando los sinonimos de las bases de datos"
    Copy-tssSynonyms -SourceEnvironment DEV -SourceSubEnvironment PRD -TargetSubEnvironment UAT
    Copy-tssSynonyms -SourceEnvironment DEV -SourceSubEnvironment PRD_OLD -TargetSubEnvironment PRD

    Write-Verbose -Message "Preparando el CDC de las bases de datos"
    Copy-tssCDCConfig -SourceEnvironment DEV -SourceSubEnvironment DEV1 -TargetSubEnvironment UAT 
    Copy-tssCDCConfig -SourceEnvironment DEV -SourceSubEnvironment DEV1 -TargetSubEnvironment PRD

    Write-Verbose -Message "Reseteando el Service Broker"
    Reset-tssServiceBroker -Environment DEV -SubEnvironment UAT 
    Reset-tssServiceBroker -Environment DEV -SubEnvironment PRD 
  
  }
  else {
    Write-Verbose "Esquivando el proceso de preparación"
  }
  
}