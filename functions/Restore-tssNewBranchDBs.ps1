function Restore-tssNewBranchDBs {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [string] $VersionArchived,

    [parameter(Mandatory = $true)]
    [string] $DBServer,

    [parameter(Mandatory = $true)]
    [string] $MainBackupPath
  )

  $DevDBs = 'PLS_AUDIT_DEV', 'PLSCONFIG_DEV', 'PLSEDI_DEV', 'PLSWEB_DEV', 'PLSPWB_DEV', 'PLS_DEV'
  $DriveMostFree = Get-DbaDiskSpace -ComputerName $DBServer | Sort-Object -Property FreeInGB -Descending | Select-Object -First 1 
  $DataDir = $DriveMostFree[0].Name + "MSSQL\DATA"
  $DBFilePrefix = $VersionArchived + "_"

  foreach ($DevDB in $DevDBs) {
    $Dev1DB = $DevDB + '_DEV1'
    $UATNewDB = $DevDB + '_UAT_NEW'
    $BackupPath = Join-Path -Path $MainBackupPath -ChildPath $Dev1DB
    
    if (-not (Test-Path -Path $BackupPath)) {
      Write-Error -Message "The backup path does not exists"
      return
    }

    if ($PSCmdlet.ShouldProcess($DBServer, "Restaurando base de datos $UATNewDB")) {
      try {
        if ($DevDB -eq 'PLS_DEV') {  
          $FileStructure = Get-tssPLSDevDBFileDistribution -DBServer $DBServer -DBFilePrefix $DBFilePrefix
          Restore-DbaDatabase -SqlServer $DBServer -Path $BackupPath `
            -MaintenanceSolutionBackup -DatabaseName $UATNewDB -FileMapping $FileStructure
        }
        else {
          Restore-DbaDatabase -SqlServer $DBServer -Path $BackupPath `
            -MaintenanceSolutionBackup -DatabaseName $UATNewDB -DestinationDataDirectory $DataDir `
            -DestinationLogDirectory $DataDir -DestinationFilePrefix $DBFilePrefix
        }
      }
      catch {
        Write-Warning -Message "La base de datos $UATNewDB no pudo ser restaurada."
        Write-Error $_
        return
      }    
    }  
  } 
}


