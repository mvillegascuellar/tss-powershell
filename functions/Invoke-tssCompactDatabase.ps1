function Invoke-tssCompactDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [Validateset('DEV', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [string] $Environment,

        [parameter(Mandatory=$true)]
        [string] $SubEnvironment,

        [parameter(Mandatory=$true)]
        [Validateset('PLS','PLSPWB')]
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
                Write-Verbose "Intentando compactar la base de datos - Segundo Intento"
                Invoke-tssShrinkPLSDatabase -PLSDatabase $PLSDB
            }

            Write-Verbose "Ejecutando limpieza de data sensible"
            Invoke-tssCleanSensitiveData -PLSDatabase $PLSDB

            if ($PSCmdlet.ShouldProcess($PLSDB,"Generando copia de seguridad de base de datos")) {
                Backup-DbaDatabase -SqlInstance $PLSDB.parent.name -Type Full -CompressBackup -Checksum -DatabaseCollection $PLSDB.name
            }

        }
        elseif ($DBType -eq 'PWB') {
            $PWBDB = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $DBType
            $PWBDB.Parent.ConnectionContext.StatementTimeout = 0

            Write-Verbose "Intentando cambiar el modelo de recuperación a simple"
            Set-tssDatabaseRecoveryModel -SqlDatabase $PWBDB -RecoveryModel Simple

            Write-Verbose "Intentando truncar las tablas no importantes"
            Clear-tssPWBNotImportantTables -SqlDatabase $PWBDB

            Write-Verbose "Intentando compactar la base de datos"
            Invoke-tssShrinkPWBDatabase -PWBDatabase $PWBDB

            if ($PSCmdlet.ShouldProcess($PWBDB,"Generando copia de seguridad de base de datos")) {
                Backup-DbaDatabase -SqlInstance $PWBDB.parent.name -Type Full -CompressBackup -Checksum -DatabaseCollection $PWBDB.name
            }

        } #end elseif para tipo de base de datos

    } #end process

} #end function

#Invoke-tssCompactDatabase -Environment DEV -SubEnvironment PRD_OLD -DBType PLS -WhatIf