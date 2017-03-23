function Copy-tssPLSApplicationSettings{
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Environment,
        [parameter(Mandatory=$true)]
        [string]$SourceSubEnvironment,
        [parameter(Mandatory=$true)]
        [string]$DestSubEnvironment
    )

    Write-Verbose "Preparando conexión a Origen"
    $EnvServer = Get-tssConnection -Environment $Environment
    [string]$SourcePLSDB = Get-tssDatabaseName -SQLServer $EnvServer -Environment $Environment -SubEnvironment $SourceSubEnvironment -Database PLS
    if ($SourcePLSDB -eq $null -or $SourcePLSDB.Trim() -eq '') {
        Write-Error "No es posible conectar a la base de datos PWB del Origen";
        return $null
    }

    Write-Verbose "Preparando conexión a Destino"
    [string]$DestPLSDB = Get-tssDatabaseName -SQLServer $EnvServer -Environment $Environment -SubEnvironment $DestSubEnvironment -Database PLS
    if ($DestPLSDB -eq $null -or $DestPLSDB.Trim() -eq '') {
        Write-Error "No es posible conectar a la base de datos PLS del Destino"
        return $null
    }

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
                                    ('XpoRealTime', 'DashboardApiUrl');

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

    Write-Verbose "Copiando Application Settings"
    Invoke-Sqlcmd2 -ServerInstance $EnvServer.Name -Database $DestPLSDB -Query $sqlCopyAppSettings

}
