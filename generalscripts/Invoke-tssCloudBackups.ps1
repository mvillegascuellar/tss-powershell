[CmdletBinding(SupportsShouldProcess)]
param (
  [string]
  $SqlInstanceName,

  [parameter(Mandatory = $true, ParameterSetName = "Retention")]
  [switch]
  $RetentionPeriod,

  [parameter(Mandatory = $false, ParameterSetName = "Retention")]
  [int16]
  $RetentionHours = 336,

  [parameter(Mandatory = $true, ParameterSetName = "DeleteLocal")]
  [switch]
  $RemoveLocal,

  [parameter(Mandatory = $true, ParameterSetName = "DeleteLocal")]
  [string]
  $BackupPath,

  [Validateset('System', 'User')]
  [parameter(Mandatory = $true)]
  [string]
  $DatabaseType,

  [Validateset('Full', 'Log')]
  [parameter(Mandatory = $true)]
  [string]
  $BackupType

)

if ($BackupType -eq 'Full') {
  $BackupExtension = 'bak'
}
if ($BackupType -eq 'Log') {
  $BackupExtension = 'trn'
}

if ($RetentionPeriod) {
  if ($SqlInstanceName.Contains('\')) {
    $SqlInstance = $SqlInstanceName.Replace('\', '_')
  }
  else {
    $SqlInstance = $SqlInstanceName
  }
  $CleanupTime = [DateTime]::UtcNow.AddHours(-1 * $RetentionHours)
  $context = New-AzureStorageContext -StorageAccountName tssbackup -StorageAccountKey {EMZqyMGjCb6fVrf8fzakXrXhxT6AYUWiYcrJjVt5mfOwJPGvccs3bKtPLBOe28Lu9r+7BHLGfq7ck6OEYT1uNg==}
  Get-AzureStorageBlob -Container "backupdb" -Context $context | 
    Where-Object { $_.LastModified.UtcDateTime -lt $CleanupTime -and $_.BlobType -eq "BlockBlob" -and $_.Name -like "$SqlInstance/$DatabaseType/*/$BackupType/*.$BackupExtension"} |
    Remove-AzureStorageBlob
}
if ($RemoveLocal) {
  if ($SqlInstanceName.Contains('\')) {
    $SqlInstance = $SqlInstanceName.Replace('\', '$')
  }
  else {
    $SqlInstance = $SqlInstanceName
  }
  $fullBackupPath = Join-Path -Path $BackupPath -ChildPath $SqlInstance
  if (-not (Test-Path -Path $fullBackupPath)) {
    Write-Error "No se encontro la ruta del backup: $fullBackupPath"
    break
  }
  if ($DatabaseType -eq 'System') {
    Get-ChildItem -Path $fullBackupPath |
      Where-Object {$_.Name -in ('master', 'model', 'msdb')} |
      Get-ChildItem -Filter "*.$BackupExtension" -Recurse |
      Remove-Item 
  }
  if ($DatabaseType -eq 'User') {
    Get-ChildItem -Path $fullBackupPath |
      Where-Object {$_.Name -notin ('master', 'model', 'msdb')} |
      Get-ChildItem -Filter "*.$BackupExtension" -Recurse |
      Remove-Item 
  }
  
}