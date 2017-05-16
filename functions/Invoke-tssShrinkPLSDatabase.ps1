function Invoke-tssShrinkPLSDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $PLSDatabase
    )

    $ResultObj = [pscustomobject]@{
					            Instancia = $PLSDatabase.parent.name
					            BaseDatos = $PLSDatabase.name
				                }

    if ($PSCmdlet.ShouldProcess($PLSDatabase,"Reducción Inicial del Log de Transacciones")) {
        $PLSDatabase.Checkpoint()
        $PLSDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
    }

    if ($PLSDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data5")){
        if ($PSCmdlet.ShouldProcess($PLSDatabase,"Compactando y Removiendo Datafile PLS_Data5")) {
            $Startdate = get-date
            $PLSdf = $PLSDatabase.FileGroups["PRIMARY"].Files["PLS_Data5"]
            $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
            $PLSdf.Drop()
            $Enddate = get-date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "DuracionShirnkDF5" -Value $duracion -MemberType NoteProperty
        }
    }

    if ($PLSDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data2")){
        if ($PSCmdlet.ShouldProcess($PLSDatabase,"Compactando y Removiendo Datafile PLS_Data2")) {
            $Startdate = get-date
            $PLSdf = $PLSDatabase.FileGroups["PRIMARY"].Files["PLS_Data2"]
            $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
            $PLSdf.Drop()
            $Enddate = get-date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "DuracionShirnkDF2" -Value $duracion -MemberType NoteProperty
        }
    }

    if ($PLSDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data3")){
        if ($PSCmdlet.ShouldProcess($PLSDatabase,"Compactando y Removiendo Datafile PLS_Data3")) {
            $Startdate = get-date
            $PLSdf = $PLSDatabase.FileGroups["PRIMARY"].Files["PLS_Data3"]
            $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
            $PLSdf.Drop()
            $Enddate = get-date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "DuracionShirnkDF3" -Value $duracion -MemberType NoteProperty
        }
    }

    if ($PSCmdlet.ShouldProcess($PLSDatabase,"Compactando base de datos completa")) {
        $Startdate = get-date
        $PLSDatabase.Shrink(0,[Microsoft.SQLServer.Management.SMO.ShrinkMethod]::Default)
        $Enddate = get-date
        $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
        $ResultObj | Add-Member -Name "DuracionShirnkDatabase" -Value $duracion -MemberType NoteProperty
    }

    if ($PSCmdlet.ShouldProcess($PLSDatabase,"Habilitando autocrecimiento")) {
        foreach ($df in $PLSDatabase.FileGroups["PRIMARY"].files) {
            $df.GrowthType = "KB"
            $df.Growth = 1 * 1MB # En realidad esto es 1GB
            $PLSDatabase.Alter()
        }
    }

    if ($PSCmdlet.ShouldProcess($PLSDatabase,"Reducción Final del Log de Transacciones")) {
        $PLSDatabase.Checkpoint()
        $PLSDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
    }

    Write-Output $ResultObj

}
