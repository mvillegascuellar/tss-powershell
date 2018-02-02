function Get-ExpiredBackups {
    param (
        # Number of Days to evaluate  Backups
        [int16]
        $BackupEvaluationDays = 14
      )

    #Full Backups Validation
    $CleanupTime = [DateTime]::UtcNow.AddDays(-1 * $BackupEvaluationDays)
    $context = New-AzureStorageContext -StorageAccountName tssbackup -StorageAccountKey {EMZqyMGjCb6fVrf8fzakXrXhxT6AYUWiYcrJjVt5mfOwJPGvccs3bKtPLBOe28Lu9r+7BHLGfq7ck6OEYT1uNg==}
    $ExpiredFullBackups = Get-AzureStorageBlob -Container "backupdb" -Context $context  | 
                            Where-Object {$_.LastModified.UtcDateTime -lt $CleanupTime -and `
                                $_.BlobType -eq "BlockBlob" -and `
                                ($_.Name -like '*/System/*' -or $_.Name -like '*/User/*') -and `
                                $_.Name -notlike 'Inactive/*' -and `
                                $_.Name -notlike 'SP/*' } |
                                Select-Object -Property @{l="BackupType";e={switch -wildcard ($_.Name) {
                                    "*.bak" { "Full" }
                                    "*.trn" { "Log" }
                                    Default {"Undefined"}
                                }}}, Name, LastModified 

    Write-Output $ExpiredFullBackups

}

function Send-ExpiredBackupAlerts {
    [CmdletBinding(SupportsShouldProcess)]
    param (
      # Backup Alerts object
      [Object]
      $BackupAlerts
    )
  
    $smtpServer = "mail.tss.com.pe"
    $To = "_TSS_DBA@tss.com.pe"
    $From = "tssbackupverifier@tss.com.pe"
    $Sender = "tssbackupverifier@tss.com.pe"

    $a = "<style>"
    $a = $a + "BODY"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}"
    $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:thistle}"
    $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color:palegoldenrod}"
    $a = $a + "</style>"

    if ($BackupAlerts -ne $null) {
      $Subject = " BackupAlerts: Backups Expired Present on Azure"
      $Body = $BackupAlerts | ConvertTo-Html -Head $a -Body "<H2>Expired Backups</H2>"
    
      $msg = new-object Net.Mail.MailMessage
      $smtp = new-object Net.Mail.SmtpClient($smtpServer)
      $smtp.port = '25'
        $msg.From = $From
        $msg.Sender = $Sender
        $msg.To.Add($To)
        $msg.Subject = $Subject
        $msg.Body = $Body
        $msg.IsBodyHtml = $True
        $smtp.Send($msg)
    }
        
  }

$res = Get-ExpiredBackups 
Send-ExpiredBackupAlerts -BackupAlerts $res  



#Where-Object {$_.LastModified.UtcDateTime -lt $CleanupTime -and $_.BlobType -eq "BlockBlob" -and $_.Name -like '*.bak'}