function Copy-tssSynonyms
{
    [CmdletBinding()]
    param (
    [parameter(Mandatory=$true)]
    [string]$SourceEnvironment,
    [parameter(Mandatory=$true)]
    [string]$SourceSubEnvironment,
    [parameter(Mandatory=$true)]
    [string]$TargetEnvironment,
    [parameter(Mandatory=$true)]
    [string]$TargetSubEnvironment,
    [parameter(Mandatory=$false)]
    [string]$TargetDBSufix
    )

    $TargetDBServer = Get-tssConnection -Environment $TargetEnvironment
    $SourceDBServer = Get-tssConnection -Environment $SourceEnvironment
    
    Write-Verbose "Preparando conexión a PLS"
    [string]$SourcePLSDBName = Get-tssDatabaseName -SQLServer $SourceDBServer -Environment $SourceEnvironment -SubEnvironment $SourceSubEnvironment -Database 'PLS'
    [string]$TargetPLSDBName = Get-tssDatabaseName -SQLServer $TargetDBServer -Environment $TargetEnvironment -SubEnvironment $TargetSubEnvironment -Database 'PLS' -DBSufix $TargetDBSufix
    if ($SourcePLSDBName -eq $null -or $SourcePLSDBName.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PLS del Origen";
        return $null
    }
    if ($TargetPLSDBName -eq $null -or $TargetPLSDBName.Trim() -eq '')
    {
        Write-Error "No es posible conectar a la base de datos PLS del Destino"
        return $null
    }

    foreach ($Synonym in $SourceDBServer.databases[$SourcePLSDBName].Synonyms)
    {
        $synonymName = $Synonym.name
        Write-Verbose "Copiando sinonimo $synonymName"
        if ($TargetDBServer.databases[$TargetPLSDBName].Synonyms.contains($synonymName))
        {
            $TargetDBServer.databases[$TargetPLSDBName].Synonyms[$synonymName].drop()
        }
        $TargetDBServer.databases[$TargetPLSDBName].ExecuteNonQuery($Synonym.script()) 
    }

}