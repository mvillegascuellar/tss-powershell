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
    $BackupPath = $MainBackupPath + $Dev1DB

    if ($PSCmdlet.ShouldProcess($DBServer, "Restaurando base de datos $UATNewDB")) {
      try {
        if ($DevDB -eq 'PLS_DEV') {  
          $PLSDriveMostFree = Get-DbaDiskSpace -ComputerName $DBServer | Sort-Object -Property FreeInGB -Descending | Select-Object -First 4
          $FileStructure = @{
            'PLS'       = "$($PLSDriveMostFree[0].Name)mssql\Data\$($DBFilePrefix)PLS_DEV_DEV1.mdf"
            'PLS_Data4' = "$($PLSDriveMostFree[1].Name)mssql\Data\$($DBFilePrefix)PLS_DEV_DEV1_4.ndf"
            'PLS_Index' = "$($PLSDriveMostFree[2].Name)mssql\Data\$($DBFilePrefix)PLS_DEV_DEV1_index.ndf"
            'PLSCDC'    = "$($PLSDriveMostFree[3].Name)mssql\Data\$($DBFilePrefix)PLS_DEV_DEV1_cdc.ndf"
            'PLS_log'   = "$($PLSDriveMostFree[3].Name)mssql\Data\$($DBFilePrefix)PLS_DEV_DEV1_log.ldf"
          }
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


