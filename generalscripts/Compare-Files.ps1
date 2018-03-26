$scriptspath = "F:\Tmp\Projects\Clark\Pedro"
$logfile = Join-Path -Path $scriptspath -ChildPath "scripts_log.txt"
New-Item -Path $logfile -ItemType File -Force
$files = Get-ChildItem -Path $scriptspath -Filter *.sql
foreach ($file in $files) {
    Add-Content -Path $logfile -Value $file.Name 
    foreach ($line in (Get-Content -Path $file.fullName)){
        if ($line -like 'Comment:*') {
            Add-Content -Path $logfile -Value $line
        }
    }
}



$scriptspath = "F:\Tmp\Projects\Clark\Pedro2"
$logfile = Join-Path -Path $scriptspath -ChildPath "scripts_log.txt"
New-Item -Path $logfile -ItemType File -Force
$files = Get-ChildItem -Path $scriptspath -Filter *.sql
foreach ($file in $files) {
    Add-Content -Path $logfile -Value $file.Name 
    foreach ($line in (Get-Content -Path $file.fullName)){
        if ($line -like '/*	up\*') {
            Add-Content -Path $logfile -Value $line
        }
    }
}


$log92 = Get-Content -Path "F:\Tmp\Projects\Clark\Pedro2\scripts_log.txt"
#$loghf = Get-Content -Path "F:\Tmp\Projects\Clark\Pedro\scripts_log.txt"
foreach ($line92 in $log92) {
    if ($line92 -like "*IM*" ){
        $Ticket92 = $line92.Split(".")[4]
        $line92.sub
        $Ticket92
    }
}

$loghf = Get-Content -Path "F:\Tmp\Projects\Clark\Pedro\scripts_log.txt"
foreach ($linehf in $loghf) {
    if ($linehf -like "Comment:*" ){
        $Tickethf = $linehf.Substring(11)
        #$Tickethf = $Tickethf.Substring(0,$Tickethf.IndexOf(" - ",7) -1)
        $Tickethf
    }
}