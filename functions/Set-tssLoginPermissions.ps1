function Set-tssLoginPermissions {
    [CmdletBinding(SupportsShouldProcess)]
    param (
         [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [parameter(Mandatory=$true)]
        [string]$Environment,
        [parameter(Mandatory=$true)]
        [string]$SubEnvironment,
        [switch]$SkipPWB
    )

    Write-Verbose "Preparando conexión a la base de datos PLS"
    $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database PLS
    

    if ($SkipPWB -eq $false) {
        Write-Verbose "Preparando conexión a la base de datos PWB"
        $PWBDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database PLSPWB
    }

    $logins = New-Object -TypeName System.Collections.ArrayList

    if ($Environment -cin ('DEV','UAT')){
        $logins.Add('tssuser') | Out-Null
    }
    if ($Environment -cin ('QA','INT','UAT','PERF')){
        $logins.Add('xpouser') | Out-Null
    }

    foreach ($login in $logins){
        Write-Verbose "Verificando si el login $login existe"
        if ($PLSDB.parent.logins.contains($login)){
            Write-Verbose "============================================"
            Write-Verbose "Configurando permisos para base de datos PLS"
            Write-Verbose "============================================"
            Write-Verbose "Verificando si el usuario $login existe"
            if ($PLSDB.Users.Contains($login) -eq $false){
                if ($PSCmdlet.ShouldProcess($PLSDB,"Creando usuario: $login")) {
                    $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PLSDB, $login)
                    $Newuser.login = $login
                    $Newuser.create()
                }
            }
            else
            {
                if ($PSCmdlet.ShouldProcess($PLSDB,"Asociando usuario con login: $login")) {
                    $sqlfixorphan = "ALTER USER " + $login + " WITH LOGIN = " + $login
                    $PLSDB.ExecuteNonQuery($sqlfixorphan) | Out-Null
                }
            }
            if ($PSCmdlet.ShouldProcess($PLSDB,"Asociando los roles de $login")) {
                $PLSDB.Roles['db_datareader'].AddMember($login)
                $PLSDB.Roles['db_datawriter'].AddMember($login)
                if ($Environment -eq 'DEV'){
                    $PLSDB.Roles['db_owner'].AddMember($login)
                }
            }

            if ($PSCmdlet.ShouldProcess($PLSDB,"Asociando los permisos de objeto de $login")) {
                $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
                $permission.Receive = $true
                $PLSDB.ServiceBroker.Queues['//XPO/RailOptimizer/DataServices/NotificationsTargetQueue'].grant($permission,$login)
                $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
                $permission.Execute = $true
                $PLSDB.Schemas['dbo'].Grant($permission,$login)
                $PLSDB.Schemas['es'].Grant($permission,$login)
                $PLSDB.Schemas['Tzdb'].Grant($permission,$login)
                $PLSDB.Schemas['xpo_portal'].Grant($permission,$login)
            }

            if ($SkipPWB -eq $false) {
                Write-Verbose "============================================"
                Write-Verbose "Configurando permisos para base de datos PWB"
                Write-Verbose "============================================"
                Write-Verbose "Verificando si el usuario $login existe"
                if ($PWBDB.Users.Contains($login) -eq $false){
                    if ($PSCmdlet.ShouldProcess($PWBDB,"Creando usuario: $login")) {
                        $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PWBDB, $login)
                        $Newuser.login = $login
                        $Newuser.create()
                    }
                }
                else
                {
                    if ($PSCmdlet.ShouldProcess($PWBDB,"Asociando usuario con login: $login")) {
                        $sqlfixorphan = "ALTER USER " + $login + " WITH LOGIN = " + $login
                        $PWBDB.ExecuteNonQuery($sqlfixorphan) | Out-Null
                    }
                }
                if ($PSCmdlet.ShouldProcess($PWBDB,"Asociando los roles de $login")) {
                    $PWBDB.Roles['db_datareader'].AddMember($login)
                    $PWBDB.Roles['db_datawriter'].AddMember($login)
                    if ($Environment -eq 'DEV'){
                        $PWBDB.Roles['db_owner'].AddMember($login)
                    }
                }
                
                if ($PSCmdlet.ShouldProcess($PWBDB,"Asociando los permisos de objeto de $login")) {
                    $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
                    $permission.Execute = $true
                    $PWBDB.Schemas['dbo'].Grant($permission,$login)
                }
            }
        }
    }
}
