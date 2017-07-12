function Invoke-tssShrinkDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $SqlDatabase,

        [parameter(Mandatory=$true)]
        [Validateset('PLS','PLSPWB')]
        [string] $DBType
    )

    $GeneralStartdate = Get-Date
    $ResultObj = [pscustomobject]@{
					            Instancia = $SqlDatabase.parent.name
					            BaseDatos = $SqlDatabase.name
				                }
    
    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Reducción Inicial del Log de Transacciones")) {
        $Startdate = Get-Date
        $SqlDatabase.Checkpoint()
        $SqlDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
        $Enddate = Get-Date
        $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
        $ResultObj | Add-Member -Name "DuracionPrimeraReduccionLog" -Value $duracion -MemberType NoteProperty
    }

    if ($DBType -eq 'PLS') {
        
        if ($SqlDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data5")){
            if ($PSCmdlet.ShouldProcess($SqlDatabase,"Compactando y Removiendo Datafile PLS_Data5")) {
                $Startdate = Get-Date
                $PLSdf = $SqlDatabase.FileGroups["PRIMARY"].Files["PLS_Data5"]
                $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
                $PLSdf.Drop()
                $Enddate = Get-Date
                $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
                $ResultObj | Add-Member -Name "DuracionShirnkDF5" -Value $duracion -MemberType NoteProperty
            }
        } # end if Shrink DF5

        if ($SqlDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data2")){
            if ($PSCmdlet.ShouldProcess($SqlDatabase,"Compactando y Removiendo Datafile PLS_Data2")) {
                $Startdate = Get-Date
                $PLSdf = $SqlDatabase.FileGroups["PRIMARY"].Files["PLS_Data2"]
                $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
                $PLSdf.Drop()
                $Enddate = Get-Date
                $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
                $ResultObj | Add-Member -Name "DuracionShirnkDF2" -Value $duracion -MemberType NoteProperty
            }
        } # end if Shrink DF2

        if ($SqlDatabase.FileGroups["PRIMARY"].Files.Contains("PLS_Data3")){
            if ($PSCmdlet.ShouldProcess($SqlDatabase,"Compactando y Removiendo Datafile PLS_Data3")) {
                $Startdate = Get-Date
                $PLSdf = $SqlDatabase.FileGroups["PRIMARY"].Files["PLS_Data3"]
                $PLSdf.Shrink(0, [Microsoft.SQLServer.Management.SMO.ShrinkMethod]::EmptyFile)
                $PLSdf.Drop()
                $Enddate = Get-Date
                $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
                $ResultObj | Add-Member -Name "DuracionShirnkDF3" -Value $duracion -MemberType NoteProperty
            }
        } # end if Shrink DF3

        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Habilitando autocrecimiento")) {
            foreach ($df in $SqlDatabase.FileGroups["PRIMARY"].files) {
                $Startdate = Get-Date
                $df.GrowthType = "KB"
                $df.Growth = 1 * 1MB # En realidad esto es 1GB
                $SqlDatabase.Alter()
                $Enddate = Get-Date
                $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
                $ResultObj | Add-Member -Name "DuracionHabilitaAutocrecimiento" -Value $duracion -MemberType NoteProperty -Force
            } # end for habilita Autocrecimiento
        } 

    } # end if DBType = PLS

    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Compactando base de datos completa")) {
        $Startdate = Get-Date
        $SqlDatabase.Shrink(0,[Microsoft.SQLServer.Management.SMO.ShrinkMethod]::Default)
        $Enddate = Get-Date
        $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
        $ResultObj | Add-Member -Name "DuracionShirnkDatabase" -Value $duracion -MemberType NoteProperty
    }

    if ($PSCmdlet.ShouldProcess($SqlDatabase,"Reducción Final del Log de Transacciones")) {
        $Startdate = Get-Date
        $SqlDatabase.Checkpoint()
        $SqlDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
        $Enddate = Get-Date
        $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
        $ResultObj | Add-Member -Name "DuracionUltimaReduccionLog" -Value $duracion -MemberType NoteProperty
    }

    $GeneralEnddate = Get-Date
    $GeneralDuration = "{0:G}" -f (New-TimeSpan -Start $GeneralStartdate -End $GeneralEnddate)
    $ResultObj | Add-Member -Name "DuracionCompletaShrinkDB" -Value $GeneralDuration -MemberType NoteProperty

    Write-Output $ResultObj

} # end fx Invoke-tssShrinkDatabase