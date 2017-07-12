function Invoke-tssNewBranchDropDBs {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [object[]]$Databases
  )

  begin {}
  process {
    foreach ($Database in $Databases) {
      if ($PSCmdlet.ShouldProcess($DevDBServer, "Eliminando base de datos $($Database.name)")) {
        try {
          Remove-DbaDatabase -SqlInstance $Database.SqlInstance -Databases $Database.name  
        }
        catch {
          Write-Warning -Message "La base de datos $($Database.name) no pudo ser eliminada."
          Write-Error $_ 
          return
        }
      }
    }
  }
  end {}
}