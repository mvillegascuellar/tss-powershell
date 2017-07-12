function Get-tssPLSDevDBFileDistribution {
  [CmdletBinding()]
  param (
    [parameter(Mandatory = $true)]
    [string] $DBServer,
    
    [parameter(Mandatory = $true)]
    [string] $DBFilePrefix
  )

  $PLSDriveMostFree = Get-DbaDiskSpace -ComputerName $DBServer | Sort-Object -Property FreeInGB -Descending | Select-Object -First 4
  $filePLS = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[0].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1.mdf"
  if ($PLSDriveMostFree.count > 1) {
    if (Test-Path	-Path(Join-Path -Path $PLSDriveMostFree[1].Name -ChildPath 'mssql\Data\')) {
      $filePLS_Data4 = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[1].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_4.mdf"
    }
  }
  if ($filePLS_Data4 -eq $null) {
    $filePLS_Data4 = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[0].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_4.mdf"
  }
          
  if ($PLSDriveMostFree.count > 2) {
    if (Test-Path	-Path(Join-Path -Path $PLSDriveMostFree[2].Name -ChildPath 'mssql\Data\')) {
      $filePLS_Index = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[2].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_index.mdf"
    }
  }
  if ($filePLS_Index -eq $null) {
    $filePLS_Index = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[0].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_index.mdf"
  }
          
  if ($PLSDriveMostFree.count > 3) {
    if (Test-Path	-Path(Join-Path -Path $PLSDriveMostFree[3].Name -ChildPath 'mssql\Data\')) {
      $filePLSCDC = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[3].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_cdc.mdf"
      $filePLS_log = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[3].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_log.mdf"
    }
  }
  if ($filePLSCDC -eq $null -and $filePLS_log -eq $null) {
    $filePLSCDC = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[0].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_cdc.mdf"
    $filePLS_log = Join-Path -Path (Join-Path -Path $PLSDriveMostFree[0].Name -ChildPath 'mssql\Data\') -ChildPath "$($DBFilePrefix)PLS_DEV_DEV1_log.mdf"
  }
          
  $FileStructure = @{
    'PLS'       = $filePLS
    'PLS_Data4' = $filePLS_Data4 
    'PLS_Index' = $filePLS_Index
    'PLSCDC'    = $filePLSCDC
    'PLS_log'   = $filePLS_log
  }
  
  Write-Output $FileStructure

}