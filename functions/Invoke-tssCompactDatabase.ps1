function Invoke-tssCompactDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [string] $Environment,

        [parameter(Mandatory=$true)]
        [string] $SubEnvironment,

        [parameter(Mandatory=$true)]
        [Validateset('PLS','PWB')]
        [string] $DBType
    )

    process {
        if ($DBType -eq 'PLS') {
            $PLSDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $DBType
            $PLSDB.Parent.ConnectionContext.StatementTimeout = 0
            
            Write-Verbose "Intentando cambiar el modelo de recuperación a simple"
            Set-tssDatabaseRecoveryModel -SqlDatabase $PLSDB -RecoveryModel Simple

            Write-Verbose "Intentando truncar las tablas no importantes"
            Clear-tssPLSNotImportantTables -SqlDatabase $PLSDB

            Write-Verbose "Intentando compactar la base de datos"
            try {
                Invoke-tssShrinkPLSDatabase -PLSDatabase $PLSDB
            }
            catch {
                Write-Verbose "Error esperado por falta de espacio y achicando log"
                $PLSDB.Checkpoint()
                $PLSDB.LogFiles[0].Shrink(0, [Microsoft.SqlServer.Management.Smo.ShrinkMethod]::TruncateOnly)
                Write-Verbose "Intentando compactar la base de datos"
                Invoke-tssShrinkPLSDatabase -PLSDatabase $PLSDB
            }

            Write-Verbose "Ejecutando limpieza de data sensible"
            Invoke-tssCleanSensitiveData -PLSDatabase $PLSDB
            
        }
    }

}

#Invoke-tssCompactDatabase -Environment DEV -SubEnvironment PRD_OLD -DBType PLS -WhatIf