function Invoke-tssTruncateNotImportantTables {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase,

        [parameter(Mandatory=$true)]
        [Validateset('PLS','PLSPWB')]
        [string] $DBType
    )

    $ResultObj = [pscustomobject]@{
					            Instancia = $SqlDatabase.parent.name
					            BaseDatos = $SqlDatabase.name
				                }
    $Startdate = Get-Date
    if ($DBType -eq 'PLS') {

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

        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Arreglando bug en heap table EquipmentIDCSRepairInfo")) {
            $SqlDatabase.ExecuteNonQuery("IF NOT EXISTS (SELECT * FROM sys.indexes 
                                    WHERE object_id = OBJECT_ID(N'[dbo].EquipmentIDCSRepairInfo') 
                                    AND name = N'cxi_EquipmentIDCSRepairInfo')
                                    CREATE CLUSTERED INDEX cxi_EquipmentIDCSRepairInfo 
                                    ON EquipmentIDCSRepairInfo (Repair_Id) ON PLSIndex") | Out-Null
        }
    } # end if DBType = PLS
    elseif ($DBType -eq 'PLSPWB') {
        
        $NotImportantTables = "dbo.Auditing_until20150204",
                              "dbo.Auditing"
    } # end elseif DBType = PLSPWB


    $Tables = Get-tssDatabaseTables -SqlDatabase $SqlDatabase -TableList $NotImportantTables

    foreach ($Table in $Tables) {
        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Truncando tabla $Table")) {
            $SqlDatabase.ExecuteNonQuery("TRUNCATE TABLE " + $Table.schema + "." + $Table.name) | Out-Null
            #Workaround as the TruncateData method does now work properly
            #$Table.truncateData()
        }
    }
    $Enddate = Get-Date
    $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
    $ResultObj | Add-Member -Name "DuracionTruncateTablasNoImportantes" -Value $duracion -MemberType NoteProperty

    Write-Output $ResultObj
}