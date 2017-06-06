function Add-tssNewDevBranch {
  <#
  .SYNOPSIS
  Rolls development databases to create a new branch for PLS
  
  .DESCRIPTION
  This cmdlet is only meant to be run a a development environment and asumes that the databases are named as follows:
  PLSXXX_DEV_DEV1 --> Current version on development
  PLSXXX_DEV_UAT --> Version developed and closed but no on production. Will be rolled as PRD
  PLSXXX_DEV_PRD --> Version on production. Will be rolled as PRD_OLD
  PLSXXX_DEV_UAT_NEW --> Copy restored from DEV1 database set that will roll as UAT
  
  .PARAMETER VersionArchived
  Version to be archived as UAT. This means version developed and closed, but not on production.
  
  .PARAMETER DevDBServer
  Name of Development Server.
  
  .PARAMETER MainBackupPath
  Path for backups of development server.
  
  .PARAMETER SkipRestore
  Skips the drop / restore phase of the process
  
  .PARAMETER SkipRename
  Skips the rename database phase of the process
  
  .PARAMETER SkipPreparation
  Skips the preparation phase of the process. In this phase synonyms are redirected, CDC is recreated and Service Brocker is reset
  
  .EXAMPLE
  Add-tssNewDevBranch -VersionArchived 347 -SkipRename -SkipPreparation -Verbose

  Will only restore the UAT_NEW database set from DEV1 databas set. All this on TSSPLSDB
  
  .EXAMPLE
  Add-tssNewDevBranch -VersionArchived 347 -SkipRestore -SkipPreparation -Verbose

  Will only rename the databases based on the following matrix:
  PLSXXX_DEV_UAT_NEW --> PLSXXX_DEV_UAT
  PLSXXX_DEV_UAT     --> PLSXXX_DEV_PRD
  PLSXXX_DEV_PRD     --> PLSXXX_DEV_PRD_OLD (Read-only)
  
  .EXAMPLE
  Add-tssNewDevBranch -VersionArchived 347 -SkipRestore -SkipRename -Verbose

  Will only prepare the newly renamed database set in order to point to the right database set.

  .EXAMPLE
  Add-tssNewDevBranch -VersionArchived 347 -DevDBServer MVILLEGAS -MainBackupPath 'D:\MSSQL\BACKUP\MVILLEGAS\' -SkipPreparation -Verbose

  Overides the DEVServer parameter and the backup path in order to make tests. Always skips preparation as the cmdlet is not prepared
  to execute this preparation tasks on another environment besides DEV (TSSPLSDB).

  #>
  
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [string] $VersionArchived,

    [parameter(Mandatory = $true)]
    [string] $DevDBServer = 'TSSPLSDB',

    [parameter(Mandatory = $true)]
    [string] $MainBackupPath = '\\tssbkp\TSS Projects\Active Projects\XPO\TSSPLSDB\',
    
    [parameter(Mandatory = $false)]
    [switch]$SkipRestore,

    [parameter(Mandatory = $false)]
    [switch]$SkipRename,

    [parameter(Mandatory = $false)]
    [switch]$SkipPreparation

  )

  #$DevDBServer = 'MVILLEGAS'
  #$MainBackupPath = 'D:\MSSQL\BACKUP\MVILLEGAS\'

  if (-not $SkipRestore) {
    
    try {
      Write-Verbose -Message "Eliminando bases de datos UAT_NEW"
      Find-DbaDatabase -SqlServer $DevDBServer -Pattern UAT_NEW | Invoke-tssNewBranchDropDBs
    }
    catch {
      Write-Warning -Message "Error eliminando las bases de datos UAT_NEW."
      Write-Error -Message $_
      return
    }

    try {
      Write-Verbose -Message "Eliminando bases de datos PRD_OLD"
      Find-DbaDatabase -SqlServer $DevDBServer -Pattern PRD_OLD | Invoke-tssNewBranchDropDBs 
    }
    catch {
      Write-Warning -Message "Error eliminando las bases de datos PRD_OLD."
      Write-Error -Message $_
      return
    }
    
    try {
      Write-Verbose -Message "Restaurando bases de datos UAT_NEW"
      Restore-tssNewBranchDBs -VersionArchived $VersionArchived -DBServer $DevDBServer -MainBackupPath $MainBackupPath 
    }
    catch {
      Write-Warning -Message "Error restaurando las bases de datos UAT_NEW."
      Write-Error -Message $_
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
      Write-Warning -Message "Error renombrando las bases de datos."
      Write-Error -Message $_
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