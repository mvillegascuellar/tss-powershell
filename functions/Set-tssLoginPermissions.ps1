function Set-tssLoginPermissions {
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
    [parameter(Mandatory = $true)]
    [string]$Environment,
        
    [parameter(Mandatory = $true)]
    [string]$SubEnvironment,

    [parameter(Mandatory = $true, ParameterSetName = "CompleteSet")]
    [switch]$AllRODBs,

    [Validateset('PLS', 'PLSPWB', 'PLSWEB', 'PLS_AUDIT', 'PLSCONFIG', 'PLSEDI')]
    [parameter(Mandatory = $true, ParameterSetName = "SpecificDBs")]
    [string[]]$RODatabases
  )

  $RODBs = New-Object -TypeName System.Collections.ArrayList
  if ($AllRODBs) {
    $RODBs.Add("PLS") | Out-Null
    $RODBs.Add("PLSPWB") | Out-Null
    $RODBs.Add("PLSWEB") | Out-Null
    $RODBs.Add("PLS_AUDIT") | Out-Null
    $RODBs.Add("PLSCONFIG") | Out-Null
    $RODBs.Add("PLSEDI") | Out-Null
  }
  else {
    $RODBs = $RODatabases
  }

  $logins = New-Object -TypeName System.Collections.ArrayList

  if ($Environment -cin ('DEV', 'DEVXPO', 'UAT')) {
    $logins.Add('tssuser') | Out-Null
  }
  if ($Environment -cin ('QA', 'INT', 'UAT', 'PERF')) {
    $logins.Add('xpouser') | Out-Null
  }
  if ($Environment -cin ('DEVXPO')) {
    $logins.Add('infosysuser') | Out-Null
  }

  foreach ($RODB in $RODBs) {
    Write-Verbose "Preparando conexión a la base de datos $RODB"
    $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $RODB

    foreach ($login in $logins) {
      Write-Verbose "Verificando si el login $login existe"
      if ($PLSDB.parent.logins.contains($login)) {
        Write-Verbose "Verificando si el usuario $login existe en base de datos $RODB"
        if ($PLSDB.Users.Contains($login) -eq $false) {
          if ($PSCmdlet.ShouldProcess($PLSDB, "Creando usuario: $login")) {
            $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PLSDB, $login)
            $Newuser.login = $login
            $Newuser.create()
          }
        }
        else {
          if ($PSCmdlet.ShouldProcess($PLSDB, "Asociando usuario con login: $login")) {
            $sqlfixorphan = "ALTER USER " + $login + " WITH LOGIN = " + $login
            $PLSDB.ExecuteNonQuery($sqlfixorphan) | Out-Null
          }
        }
        if ($PSCmdlet.ShouldProcess($PLSDB, "Asociando los roles de $login")) {
          $PLSDB.Roles['db_datareader'].AddMember($login)
          $PLSDB.Roles['db_datawriter'].AddMember($login)
          if ($Environment -cin ('DEV', 'DEVXPO')) {
            $PLSDB.Roles['db_owner'].AddMember($login)
          }
        }

        <#
        if ($Environment -eq 'DEV') {
          if ($PSCmdlet.ShouldProcess($PLSDB, "Asociando al grupo de analistas como db_owner")) {
            if ($PLSDB.Users.Contains($AnalystsGroup) -eq $false) {
              $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PLSDB, $AnalystsGroup)
              $Newuser.login = $AnalystsGroup
              $Newuser.create()
            }
            $PLSDB.Roles['db_owner'].AddMember($AnalystsGroup)
          }
        }
        #>

        if ($RODB -eq 'PLS') {
          if ($PSCmdlet.ShouldProcess($PLSDB, "Asociando los permisos de objeto de $login")) {
            $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
            $permission.Receive = $true
            $PLSDB.ServiceBroker.Queues['//XPO/RailOptimizer/DataServices/NotificationsTargetQueue'].grant($permission, $login)
            $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
            $permission.Execute = $true
            $PLSDB.Schemas['dbo'].Grant($permission, $login)
            $PLSDB.Schemas['es'].Grant($permission, $login)
            $PLSDB.Schemas['Tzdb'].Grant($permission, $login)
            $PLSDB.Schemas['xpo_portal'].Grant($permission, $login)
          }
        }
       
      }
    }

  }
  
}
