function Copy-tssPLSApplicationSettings{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [string]$Environment,
        [parameter(Mandatory=$true)]
        [string]$SourceSubEnvironment,
        [parameter(Mandatory=$true)]
        [string]$DestSubEnvironment
    )

    Write-Verbose "Preparando conexión a Origen"
    $SourcePLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SourceSubEnvironment -Database PLS

    Write-Verbose "Preparando conexión a Destino"
    $TargetPLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $DestSubEnvironment -Database PLS
    

  [string] $sqlCopyAppSettings = "declare @t_configurations TABLE
                                    (GroupName varchar(50)
                                    ,Name	varchar(50))

                                    INSERT INTO @t_configurations 
                                    VALUES ('Customer Order', 'AutoApproveAccessorialsReceiversList'),
                                    ('CustomerInvoice', 'DefaultPrinter'),
                                    ('CustomerInvoice', 'InvoicePrintFolder'),
                                    ('CustomerInvoice', 'DocReqPrintFolder'),
                                    ('Equipment', 'UserEDICreateEquipment'),
                                    ('File Server', 'FileServerPath'),
                                    ('GeocodingAPI', 'Key'),
                                    ('MisuseReport', 'DistributionList'),
                                    ('Orders', 'UserEDIUpdateOrders'),
                                    ('Pricing', 'WarningMessageSendEmailUser'),
                                    ('Pricing', 'DOEFuelIndexEmailSender'),
                                    ('Quote', 'QuoteLaneRouteEmailAddress'),
                                    ('Work Order', 'RailBillingEmail'),
                                    ('Work Order', 'RSCNotificationCC'),
                                    ('XpoRealTime', 'CustomerOrderBoardUrl'),
                                    ('XpoRealTime', 'WorkOrderBoardUrl'),
                                    ('XpoRealTime', 'OrderChargeBoardUrl'),
                                    ('XpoRealTime', 'DashboardApiUrl'),
                                    ('XpoRealTime', 'EquipmentBoardUrl');

                                    update a
                                    set a.Value = b.Value
                                    ,UpdatedBy = 'RefreshEnv'
                                    ,UpdateDate = getdate()
                                    from ApplicationSetting a
                                    inner join $SourcePLSDB.dbo.ApplicationSetting b
                                    on a.GroupName = b.GroupName
                                    and a.Name = b.Name
                                    where EXISTS (SELECT 1
	                                     FROM @t_configurations c
	                                    WHERE a.GroupName = c.GroupName
	                                    AND a.Name = c.Name)"
 

    if ($PSCmdlet.ShouldProcess($TargetPLSDB,"Copiando Application Settings")) {
        $TargetPLSDB.ExecuteNonQuery($sqlCopyAppSettings)
    }
}
