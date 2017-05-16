function Invoke-tssShrinkPWBDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [object] $PWBDatabase
    )

    $ResultObj = [pscustomobject]@{
					            Instancia = $PWBDatabase.parent.name
					            BaseDatos = $PWBDatabase.name
				                }

    if ($PSCmdlet.ShouldProcess($PWBDatabase,"Reduciendo el Log de Transacciones")) {
        $PWBDatabase.Checkpoint()
        $PWBDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
    }

    if ($PSCmdlet.ShouldProcess($PWBDatabase,"Compactando base de datos completa")) {
        $Startdate = get-date
        $PWBDatabase.Shrink(0,[Microsoft.SQLServer.Management.SMO.ShrinkMethod]::Default)
        $Enddate = get-date
        $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
        $ResultObj | Add-Member -Name "DuracionShirnkDatabase" -Value $duracion -MemberType NoteProperty
    }

    if ($PSCmdlet.ShouldProcess($PWBDatabase,"Reduciendo el Log de Transacciones")) {
        $PWBDatabase.Checkpoint()
        $PWBDatabase.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
    }

    Write-Output $ResultObj

}