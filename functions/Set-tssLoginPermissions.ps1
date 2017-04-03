function Set-tssLoginPermissions {
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Environment,
        [parameter(Mandatory=$true)]
        [string]$SubEnvironment,
        [switch]$SkipPWB
    )

    Write-Verbose "Preparando conexión a la base de datos"
    $EnvServer = Get-tssConnection -Environment $Environment
    [string]$PLSDBName = Get-tssDatabaseName -SQLServer $EnvServer -Environment $Environment -SubEnvironment $SubEnvironment -Database PLS
    if ($PLSDBName -eq $null -or $PLSDBName.Trim() -eq '') {
        Write-Error "No es posible conectar a la base de datos PLS";
        return $null
    }
    $PLSDB = $EnvServer.databases[$PLSDBName]

    if ($SkipPWB -eq $false) {
        [string]$PWBDBName = Get-tssDatabaseName -SQLServer $EnvServer -Environment $Environment -SubEnvironment $SubEnvironment -Database PLSPWB
        if ($PWBDBName -eq $null -or $PWBDBName.Trim() -eq '') {
            Write-Error "No es posible conectar a la base de datos PWB";
            return $null
        }
        $PWBDB = $EnvServer.databases[$PWBDBName]
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
        if ($EnvServer.logins.contains($login)){
            Write-Verbose "============================================"
            Write-Verbose "Configurando permisos para base de datos PLS"
            Write-Verbose "============================================"
            Write-Verbose "Verificando si el usuario $login existe"
            if ($PLSDB.Users.Contains($login) -eq $false){
                $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PLSDB, $login)
                $Newuser.login = $login
                $Newuser.create()
            }
            Write-Verbose "Asociando los roles de $login"
            $PLSDB.Roles['db_datareader'].AddMember($login)
            $PLSDB.Roles['db_datawriter'].AddMember($login)
            if ($Environment -eq 'DEV'){
                $PLSDB.Roles['db_owner'].AddMember($login)
            }

            Write-Verbose "Asociando los permisos de objeto de $login"
            $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
            $permission.Receive = $true
            $PLSDB.ServiceBroker.Queues['//XPO/RailOptimizer/DataServices/NotificationsTargetQueue'].grant($permission,$login)
            $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
            $permission.Execute = $true
            $PLSDB.Schemas['dbo'].Grant($permission,$login)
            $PLSDB.Schemas['es'].Grant($permission,$login)
            $PLSDB.Schemas['Tzdb'].Grant($permission,$login)
            $PLSDB.Schemas['xpo_portal'].Grant($permission,$login)

            if ($SkipPWB -eq $false) {
                Write-Verbose "============================================"
                Write-Verbose "Configurando permisos para base de datos PWB"
                Write-Verbose "============================================"
                Write-Verbose "Verificando si el usuario $login existe"
                if ($PWBDB.Users.Contains($login) -eq $false){
                    $Newuser = New-Object ('Microsoft.SqlServer.Management.Smo.User') ($PWBDB, $login)
                    $Newuser.login = $login
                    $Newuser.create()
                }
                Write-Verbose "Asociando los roles de $login"
                $PWBDB.Roles['db_datareader'].AddMember($login)
                $PWBDB.Roles['db_datawriter'].AddMember($login)
                if ($Environment -eq 'DEV'){
                    $PWBDB.Roles['db_owner'].AddMember($login)
                }
                
                Write-Verbose "Asociando los permisos de objeto de $login"
                $permission = New-Object -typeName Microsoft.SqlServer.Management.Smo.ObjectPermissionSet
                $permission.Execute = $true
                $PWBDB.Schemas['dbo'].Grant($permission,$login)
            }
        }
    }
}
#Set-tssLoginPermissions -Environment DEV -SubEnvironment PRD_OLD  -Verbose