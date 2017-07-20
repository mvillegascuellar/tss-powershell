function Invoke-tssCompactDatabase {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory=$true)]
        [Validateset('DEV', 'DEVXPO', 'INT', 'QA', 'UAT', 'PERF', 'PROD', 'LOCAL', 'DBA')]
        [string] $Environment,

        [parameter(Mandatory=$true)]
        [string] $SubEnvironment,

        [parameter(Mandatory=$true)]
        [Validateset('PLS','PLSPWB')]
        [string] $DBType
    )

    begin {
        $SqlDatabase = Get-tssDatabase -Environment $Environment -SubEnvironment $SubEnvironment -Database $DBType
        $SqlDatabase.Parent.ConnectionContext.StatementTimeout = 0
        
        $ResultObj = [pscustomobject]@{
					                  Ambiente = $Environment
					                  SubAmbiente = $SubEnvironment
                                      Instancia = $SqlDatabase.parent.name
                                      BaseDatos = $SqlDatabase.name
				                      }
        
    }

    process {

        $GeneralStartDate = Get-Date

        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Cambiando el modelo de recuperación a Simple")) {
            $RecObject = Set-tssDatabaseRecoveryModel -SqlDatabase $SqlDatabase -RecoveryModel Simple
            $ResultObj | Add-Member -Name "CambioModeloRecuperacionRealizado" -Value $RecObject.CambioRealizado -MemberType NoteProperty
            if ($RecObject.CambioRealizado) {
                $ResultObj | Add-Member -Name "DuracionCambioModeloRecuperacion" -Value $RecObject.DuracionCambioModeloRecuperacion -MemberType NoteProperty
            }
        }

        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Truncando las tablas no importantes")) {
            $TruncObj = Invoke-tssTruncateNotImportantTables -SqlDatabase $SqlDatabase -DBType $DBType
            $ResultObj | Add-Member -Name "DuracionTruncateTablasNoImportantes" -Value $TruncObj.DuracionTruncateTablasNoImportantes -MemberType NoteProperty
        }

        if ($DBType -eq 'PLS') {
            if ($PSCmdlet.ShouldProcess($SqlDatabase,"Limpieza de Data Sensible")) {
                $CleanDataObj = Invoke-tssCleanSensitiveData -PLSDatabase $SqlDatabase
                $ResultObj | Add-Member -Name "ScriptLimpieza" -Value $CleanDataObj.ScriptLimpieza -MemberType NoteProperty
                $ResultObj | Add-Member -Name "DuracionLimpiezaDataSensible" -Value $CleanDataObj.DuracionLimpiezaDataSensible -MemberType NoteProperty
            }
        }
        
        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Compactando la base de datos")) {
            try {
                $ShrinkObj = Invoke-tssShrinkDatabase -SqlDatabase $SqlDatabase -DBType $DBType
            }
            catch {
                Write-Verbose "Error Esperado - Segundo Intento de compactar la base de datos"
                $ShrinkObj = Invoke-tssShrinkDatabase -SqlDatabase $SqlDatabase -DBType $DBType
            }

            $ShrinkProps = Get-Member -InputObject $ShrinkObj -MemberType NoteProperty
            foreach($ShrinkProp in $ShrinkProps) {
                if ($ShrinkProp.name -notin ('Instancia','BaseDatos')) {
                    $propValue = $ShrinkObj | Select-Object -ExpandProperty $ShrinkProp.Name
                    $ResultObj | Add-Member -Name $ShrinkProp.Name -Value $propValue -MemberType NoteProperty
                }
            }
        }

        if ($PSCmdlet.ShouldProcess($SqlDatabase,"Generando copia de seguridad de base de datos")) {
            $Startdate = Get-Date
            $backupObj = Backup-DbaDatabase -SqlInstance $SqlDatabase.parent.name -Type Database -CompressBackup -Checksum -Databases $SqlDatabase.name
            $Enddate = Get-Date
            $duracion = "{0:G}" -f (New-TimeSpan -Start $Startdate -End $EndDate)
            $ResultObj | Add-Member -Name "BackupPath" -Value $backupObj.BackupPath -MemberType NoteProperty
            $ResultObj | Add-Member -Name "DuracionBackup" -Value $duracion -MemberType NoteProperty
        }

        $GeneralEndDate = Get-Date
        $GeneralDuration = "{0:G}" -f (New-TimeSpan -Start $GeneralStartDate -End $GeneralEndDate)
        $ResultObj | Add-Member -Name "InicioProceso" -Value $GeneralStartDate -MemberType NoteProperty
        $ResultObj | Add-Member -Name "FinProceso" -Value $GeneralEndDate -MemberType NoteProperty
        $ResultObj | Add-Member -Name "DuracionProcesoCompleto" -Value $GeneralDuration -MemberType NoteProperty

        Write-Output $ResultObj
        

    } #end process

} #end function

#Invoke-tssCompactDatabase -Environment DEV -SubEnvironment PRD_OLD -DBType PLS -WhatIf