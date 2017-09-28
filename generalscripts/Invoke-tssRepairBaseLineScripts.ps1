[CmdletBinding(SupportsShouldProcess)]
param (
  [string]
  $FilesPath,

  [Validateset('View', 'Function', 'Procedure')]
  [parameter(Mandatory = $true)]
  [string]
  $FileType
)

$ResultPath = Join-Path -Path $FilesPath -ChildPath "Modified"
New-Item -Path $FilesPath -Name "Modified" -ItemType Directory -Force | Out-Null


ForEach ($file in (Get-ChildItem -Path $FilesPath -File)) {
  $content = Get-Content -Path $file.fullName
  $schema = $file.Name.split('.')[0]
  $objectname = $file.Name.split('.')[1]

  if ($FileType -ne 'Procedure') {
    for ($i = 0; $i -lt $content.Length; $i++) {
      if ($content[$i].ToUpper().startsWith("DROP $($FileType.ToUpper())")) {
        if ($FileType -eq 'View') {
          $ModifiedLines += "IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'V'))`n"
          $ModifiedLines += "BEGIN`n"
          $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE VIEW [$schema].[$objectname] AS select 1 as col1' `n"
          $ModifiedLines += "END`n"
        }
        if ($FileType -eq 'Function') {
          $ModifiedLines += "IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))`n"
          $ModifiedLines += "BEGIN`n"
          $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$schema].[$objectname] () RETURNS INT AS BEGIN RETURN 0 END' `n"
          $ModifiedLines += "END`n"
        }
      }
      elseif ($content[$i].ToUpper().startsWith("CREATE $($FileType.ToUpper())")) {
        $ModifiedLines += $content[$i].replace('CREATE', 'ALTER') + "`n"
      }
      else {
        $ModifiedLines += $content[$i] + "`n"
      }
    }
  }
  else {
    $ModifiedLines = $content
  }

  
  if ($FileType -eq 'Function') {
    $RepString = '.UserDefinedFunction'
  }
  if ($FileType -eq 'Procedure') {
    $RepString = '.StoredProcedure'
  }
  if ($FileType -eq 'View') {
    $RepString = '.View'
  }
  
  $NewFile = Join-Path -Path $ResultPath -ChildPath $file.Name.replace($RepString, '')
  $ModifiedLines | Out-File -FilePath $NewFile
}