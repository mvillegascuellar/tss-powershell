function Copy-tssTable {
  [CmdletBinding(SupportsShouldProcess)]
  Param ( 
    [parameter(Mandatory = $true)] 
    [object] $SourceDB,

    [parameter(Mandatory = $true)]  
    [string] $SrcTable, 

    [object] $TargetDB,

    [string] $DestTable, 

    [switch] $Truncate 
  ) 

  Function ConnectionString([string] $ServerName, [string] $DbName) { 
    "Data Source=$ServerName;Initial Catalog=$DbName;Integrated Security=True;" 
  }
 
  ########## Main body ############  
  if ($TargetDB.Length -eq 0) {
    $TargetDB = $SourceDB
  }
 
  If ($DestTable.Length -eq 0) { 
    $DestTable = $SrcTable 
  } 

  if ($SourceDB.Equals($TargetDB) -and $SrcTable -eq $DestTable) {
    Write-Error -Message "La tabla Origen y Destino son las mismas"
    break
  }

  if (-not $TargetDB.tables.contains($DestTable)) {
    $TargetDB.ExecuteNonQuery($SourceDB.tables[$SrcTable].script())
  }
 
  If ($Truncate) {  
    if ($PSCmdlet.ShouldProcess($TargetDB, "Truncando Tabla $DestTable")) {
      $TruncateSql = "TRUNCATE TABLE " + $DestTable 
      $TargetDB.ExecuteNonQuery($TruncateSql)
    }
  } 
 
  $SrcConn = $SourceDB.parent.ConnectionContext.copy()
  $SrcConn.DatabaseName = $SourceDB.name
  $SrcConn.connect()
  $CmdText = "SELECT * FROM " + $SrcTable 
  $SqlReader = $SrcConn.ExecuteReader($CmdText)
  
  Try { 
    if ($PSCmdlet.ShouldProcess($TargetDB, "Copiando Tabla $SrcTable")) {
      $DestConn = $TargetDB.parent.ConnectionContext.copy()
      $DestConn.DatabaseName = $TargetDB.name
      $DestConn.connect()
      $bulkCopy = New-Object Data.SqlClient.SqlBulkCopy($DestConn, [System.Data.SqlClient.SqlBulkCopyOptions]::KeepIdentity) 
      $bulkCopy.DestinationTableName = $DestTable 
      $bulkCopy.WriteToServer($sqlReader) 
    }  
  } 
  Catch [System.Exception] { 
    $ex = $_.Exception 
    Write-Host $ex.Message 
  } 
  Finally { 
    $SqlReader.close() 
    $SrcConn.disconnect() 
    $DestConn.disconnect() 
    $bulkCopy.Close() 
  }

}