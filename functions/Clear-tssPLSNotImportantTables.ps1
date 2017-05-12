function Clear-tssPLSNotImportantTables {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase
    )

    #$PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database PLS

    $NotImportantTables = "dbo.useractivityloghistory",
                          "dbo.LineHaulAlert",
                          "dbo.LineHaulProcessLog",
                          "dbo.UserActivityLog",
                          "dbo.AuditBPNotifyConfiguration",
                          "PreLinehaulArchive.LineHaulAlert",
                          "PreLinehaulArchive.LineHaulEvent",
                          "PreLinehaulArchive.LineHaulEventReference",
                          "PreLinehaulArchive.LineHaulProcessLog",
                          "dbo.LineHaulAlert_Archive",
                          "dbo.LineHaulEvent_Archive",
                          "dbo.LineHaulEventReference_Archive",
                          "dbo.LineHaulProcessLog_Archive",
                          "dbo.LineHaulIDs"

    $Tables = Get-tssDatabaseTables -SqlDatabase $SqlDatabase -TableList $NotImportantTables

    foreach ($Table in $Tables) {
        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Truncando tabla $Table")) {
            $SqlDatabase.ExecuteNonQuery("TRUNCATE TABLE " + $Table.schema + "." + $Table.name) | Out-Null
            #Workaround as the TruncateData method does now work properly
            #$Table.truncateData()
        }
    }

    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Arreglando bug en heap table EquipmentIDCSRepairInfo")) {
        $SqlDatabase.ExecuteNonQuery("IF NOT EXISTS (SELECT * FROM sys.indexes 
                                WHERE object_id = OBJECT_ID(N'[dbo].EquipmentIDCSRepairInfo') 
                                AND name = N'cxi_EquipmentIDCSRepairInfo')
                                CREATE CLUSTERED INDEX cxi_EquipmentIDCSRepairInfo 
                                ON EquipmentIDCSRepairInfo (Repair_Id) ON PLSIndex") | Out-Null
    }
}
