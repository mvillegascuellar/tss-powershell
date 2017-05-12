function Get-tssDatabaseTables {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase,

        [parameter(Mandatory=$true)]
        [string[]] $TableList
    )

    PROCESS {
        
        foreach ($Table in $TableList) {
            if ($Table.Contains('.')) {
                $schema = ($Table -split "\.")[0]
                $TabName = ($Table -split "\.")[1]
            }
            else {
                $schema = "dbo"
                $TabName = $Table
            }

            Write-Output $SqlDatabase.Tables | Where-Object {$_.schema -eq $schema -and $_.name -eq $TabName}
        }
    }


}
