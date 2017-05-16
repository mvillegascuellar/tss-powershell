function Clear-tssPWBNotImportantTables {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase
    )

    #$PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database PLS

    $NotImportantTables = "dbo.Auditing_until20150204",
                          "dbo.Auditing"

    $Tables = Get-tssDatabaseTables -SqlDatabase $SqlDatabase -TableList $NotImportantTables

    foreach ($Table in $Tables) {
        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Truncando tabla $Table")) {
            $SqlDatabase.ExecuteNonQuery("TRUNCATE TABLE " + $Table.schema + "." + $Table.name) | Out-Null
            #Workaround as the TruncateData method does now work properly
            #$Table.truncateData()
        }
    }

}
