function Invoke-tssNewBranchRenameDBs {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [parameter(Mandatory = $true)]
    [string] $DBServer
  )

  $DevDBs = 'PLS_AUDIT_DEV', 'PLSCONFIG_DEV', 'PLSEDI_DEV', 'PLSWEB_DEV', 'PLSPWB_DEV', 'PLS_DEV'
  foreach ($DevDB in $DevDBs) {
    $SqlInstance = Connect-DbaSqlServer -SqlServer $DBServer
    $PRDDB = $DevDB + "_PRD"
    $PRDOldDB = $DevDB + "_PRD_OLD"
    $UATDB = $DevDB + "_UAT"
    $UATNewDB = $DevDB + "_UAT_NEW"

    Write-Verbose -Message "Validando la existencia de la base de datos $PRDDB"
    if (-not $SqlInstance.Databases.Contains($PRDDB)) {
      Write-Warning -Message "La base de datos $PRDDB no existe."
      return
    }
    Write-Verbose -Message "Validando la existencia de la base de datos $UATDB"
    if (-not $SqlInstance.Databases.Contains($UATDB)) {
      Write-Warning -Message "La base de datos $UATDB no existe."
      return
    }
    Write-Verbose -Message "Validando la existencia de la base de datos $UATNewDB"
    if ( -not $SqlInstance.Databases.Contains($UATNewDB)) {
      Write-Warning -Message "La base de datos $UATNewDB no existe."
      return
    }
    if ($PSCmdlet.ShouldProcess($DBServer, "Renombrando la base de datos $PRDDB")) {
      try {
        Write-Verbose -Message "Deshabilitando CDC en la base de datos $PRDDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database $PRDDB -Query "EXEC sp_cdc_disable_db"
        Write-Verbose -Message "Matando todas las conexiones y colocando como SINGLE_USER la base de datos $PRDDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $PRDDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        Write-Verbose -Message "Cambiando de nombre a la base de datos $PRDDB a $PRDOldDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "EXEC sp_renamedb '$PRDDB','$PRDOldDB'"
        Write-Verbose -Message "Regresando la base de datos $PRDOldDB a MULTI_USER"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $PRDOldDB SET MULTI_USER"
        Write-Verbose -Message "Colocando la base de datos $PRDOldDB en READ_ONLY"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $PRDOldDB SET READ_ONLY"  
      }
      catch {
        Write-Warning -Message "La base de datos $PRDDB no pudo ser renombrada."
        Write-Error $_
        return
      }
      
    }

    if ($PSCmdlet.ShouldProcess($DBServer, "Renombrando la base de datos $UATDB")) {
      try {
        Write-Verbose -Message "Deshabilitando CDC en la base de datos $UATDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database $UATDB -Query "EXEC sp_cdc_disable_db"
        Write-Verbose -Message "Matando todas las conexiones y colocando como SINGLE_USER la base de datos $UATDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $UATDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        Write-Verbose -Message "Cambiando de nombre a la base de datos $UATDB a $PRDDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "EXEC sp_renamedb '$UATDB','$PRDDB'"
        Write-Verbose -Message "Regresando la base de datos $PRDDB a MULTI_USER"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $PRDDB SET MULTI_USER"
      }
      catch {
        Write-Warning -Message "La base de datos $UATDB no pudo ser renombrada."
        Write-Error $_
        return
      }
      
    }
    
    if ($PSCmdlet.ShouldProcess($DBServer, "Renombrando la base de datos $UATNewDB")) {
      try {
        Write-Verbose -Message "Matando todas las conexiones y colocando como SINGLE_USER la base de datos $UATNewDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $UATNewDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE"
        Write-Verbose -Message "Cambiando de nombre a la base de datos $UATNewDB a $UATDB"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "EXEC sp_renamedb '$UATNewDB','$UATDB'"
        Write-Verbose -Message "Regresando la base de datos $UATDB a MULTI_USER"
        Invoke-Sqlcmd2 -ServerInstance $DBServer -Database "master" -Query "ALTER DATABASE $UATDB SET MULTI_USER"
      }
      catch {
        Write-Warning -Message "La base de datos $UATDB no pudo ser renombrada."
        Write-Error $_
        return
      }
    }
  }

}  