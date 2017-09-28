Import-Module dbatools
function Get-BackupAlerts {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    # Name of the SQL Server Instances to Evaluate
    [Parameter(Mandatory = $true)]
    [String[]]
    $SqlInstances,

    # Number of Days to evaluate Full Backups
    [int16]
    $BackupFullDays = 7,

    # Number of Days to evaluate Log Backups
    [int16]
    $BackupLogDays = 1
  )

  process {
    foreach ($SqlInstance in $SqlInstances) {
      $dbs = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeDatabase tempdb, model -Status "Normal" -Access ReadWrite | 
             Where-Object {$_.IsAccessible -eq $true -and $_.CreateDate -lt (Get-Date).AddDays(-1 * $BackupFullDays)}
      foreach ($db in $dbs) {
        $FullBackup = Get-DbaBackupHistory -SqlInstance $SqlInstance -Database $db.Name -Since (Get-Date).AddDays(-1 * $BackupFullDays) -Type Full
        if ($FullBackup.length -le 0) {
          $DbNoBackup = [PSCustomObject]@{Instancia = $db.SqlInstance
            BaseDatos = $db.Name
            TipoBackup = 'Full'
            UltimoBackup = $db.LastBackupDate
          }
          Write-Output $DbNoBackup
        }
        if ($db.RecoveryModel -eq 'Full') {
          $LogBackup = Get-DbaBackupHistory -SqlInstance $SqlInstance -Database $db.Name -Since (Get-Date).AddDays(-1 * $BackupLogDays) -Type Log 
          if ($LogBackup.length -le 0) {
            $DbNoBackup = [PSCustomObject]@{Instancia = $db.SqlInstance
              BaseDatos = $db.Name
              TipoBackup = 'Log'
              UltimoBackup = $db.LastLogBackupDate
            }
            Write-Output $DbNoBackup
          } 
        }
      }
    }
  }
}

function Send-BackupAlerts {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    # Backup Alerts object
    [Object]
    $BackupAlerts
  )

  $smtpServer = "mail.tss.com.pe"
  $To = "michael.villegas@tss.com.pe"
  $From = "tssbackupverifier@tss.com.pe"
  $Sender = "tssbackupverifier@tss.com.pe"
  if ($BackupAlerts -ne $null) {
    $Subject = " BackupAlerts: Databases without recent backups"
    $Body = $BackupAlerts | ConvertTo-Html
  }
  else {
    $Subject = " BackupAlerts: Database Backups are ok"
    $Body = "<H1>All Database Backups are Current</H1>"
  }
  
  $msg = new-object Net.Mail.MailMessage
  $smtp = new-object Net.Mail.SmtpClient($smtpServer)
  $smtp.port = '25'
  $msg.From = $From
  $msg.Sender = $Sender
  $msg.To.Add("_TSS_DBA@tss.com.pe")
  #$msg.To.Add("michael.villegas@tss.com.pe")
  #$msg.To.Add("nicolas.nakasone@tss.com.pe")
  #$msg.To.Add("adolfo.quesquen@tss.com.pe")
  $msg.Subject = $Subject
  $msg.Body = $Body
  $msg.IsBodyHtml = $True
  $smtp.Send($msg)
}

$servers = "sp13-bdapp", "erwin", "TSSATTENDANCEMP01", "TSS_CLARKSQL", "TSS_CLARKSQL\SQL2014", "IssuesSrv", "TSSCONTOPSADB", "TSSULTRATUGTF", "TSSUMARDB", "TSSUMARDB\SQL2014"
$res = Get-BackupAlerts -SqlInstances $servers
Send-BackupAlerts -BackupAlerts $res