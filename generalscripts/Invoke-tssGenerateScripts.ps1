param (
  [parameter(Mandatory = $true)]
  [string]
  $SqlInstance,

  [parameter(Mandatory = $true)]
  [string]
  $Database,

  [parameter(Mandatory = $true)]
  [string]
  $FilesPath,

  [Validateset('View', 'Function', 'Procedure')]
  [parameter(Mandatory = $true)]
  [string]
  $FileType
)

$TableFunctions = New-Object -TypeName System.Collections.ArrayList

$scriptOpts = New-DbaScriptingOption
$scriptOpts.IncludeDatabaseContext = $false
$scriptOpts.IncludeHeaders = $false

if ($FileType -eq 'Procedure'){
    $scriptOpts.IncludeIfNotExists = $true
    $objs = Get-DbaDbStoredProcedure -SqlInstance $SqlInstance -Database $Database -ExcludeSystemSp
    $objectFolder = "sprocs"
}
if ($FileType -eq 'Function'){
    #$scriptOpts.ScriptDrops = $true
    $objs = Get-DbaDatabaseUdf -SqlInstance $SqlInstance -Database $Database -ExcludeSystemUdf #| Select-Object -First 1
    $objectFolder = "functions"
    
}
if ($FileType -eq 'View'){
    #$scriptOpts.ScriptDrops = $true
    $objs = Get-DbaDatabaseView -SqlInstance $SqlInstance -Database $Database -ExcludeSystemView
    $objectFolder = "views"
    
}

$objectPath = Join-Path -Path $FilesPath -ChildPath $objectFolder

if (!(Test-Path -Path $objectPath)) {
    new-item  -Path $objectPath -ItemType Directory | Out-Null
}

$objs | ForEach-Object {
    if (!($_.IsEncrypted)) {
        if (($FileType -eq 'Function') -and ($_.functionType -eq "Table")){
            $TableFunctions.Add($_.Name) | Out-Null
            #$_ | Export-DbaScript -ScriptingOptionsObject $scriptOpts -Path (Join-Path -Path $objectPath -ChildPath ($_.Schema + '.' + $_.Name + ".FT.sql"))         
        }
        $_ | Export-DbaScript -ScriptingOptionsObject $scriptOpts -Path (Join-Path -Path $objectPath -ChildPath ($_.Schema + '.' + $_.Name + ".sql"))     
    }
}

#Remove n first header lines
# $tmpPath = Join-Path -Path $objectPath -ChildPath "out-tmp"
# if (!(Test-Path -Path $tmpPath)) {
#     new-item  -Path $tmpPath -ItemType Directory  | Out-Null
# }
Get-ChildItem -Path $objectPath -File | 
ForEach-Object {
    $content = Get-Content -Path $_.FullName | Select-Object -Skip 4 
    $schema = $_.Name.split('.')[0]
    $objectname = $_.Name.split('.')[1]
    $ModifiedLines = ""
    if ($FileType -eq 'View') {
        $ModifiedLines += "IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'V'))`n"
        $ModifiedLines += "BEGIN`n"
        $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE VIEW [$schema].[$objectname] AS select 1 as col1' `n"
        $ModifiedLines += "END`n"
    }
    if ($FileType -eq 'Function') {
        $ModifiedLines += "IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))`n"
        $ModifiedLines += "BEGIN`n"
        if ($TableFunctions.Contains($objectname)) {
        
        # if ($_.Name.endswith(".FT.sql")) {
            $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$schema].[$objectname] () RETURNS @t TABLE (x int) AS BEGIN RETURN END' "
        }
        else {
            $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$schema].[$objectname] () RETURNS INT AS BEGIN RETURN 0 END' `n"
        }
        $ModifiedLines += "END`n"
    }
    $ModifiedLines | Out-File -FilePath $_.FullName
    $content -ireplace "^CREATE\s+$FileType","ALTER $($FileType.ToUpper())" | Out-File -FilePath $_.FullName -Append
}

    



    
    # if ($FileType -in ('View','Function')) {
    #     $schema = $_.Name.split('.')[0]
    #     $objectname = $_.Name.split('.')[1]
    #     $ModifiedLines = ""
    #     for ($i = 0; $i -lt $content.Length; $i++) {
    #         if ($content[$i].ToUpper().startsWith("DROP $($FileType.ToUpper())")) {
    #             if ($FileType -eq 'View') {
    #                 $ModifiedLines += "IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'V'))`n"
    #                 $ModifiedLines += "BEGIN`n"
    #                 $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE VIEW [$schema].[$objectname] AS select 1 as col1' `n"
    #                 $ModifiedLines += "END`n"
    #             }
    #             if ($FileType -eq 'Function') {
    #                 $ModifiedLines += "IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[$schema].[$objectname]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))`n"
    #                 $ModifiedLines += "BEGIN`n"
    #                 if ($_.Name.endswith(".FT.sql")) {
    #                     $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$schema].[$objectname] () RETURNS @t TABLE (x int) AS BEGIN RETURN END' "
    #                 }
    #                 else {
    #                     $ModifiedLines += "EXEC dbo.sp_executesql @statement = N'CREATE FUNCTION [$schema].[$objectname] () RETURNS INT AS BEGIN RETURN 0 END' `n"
    #                 }
    #                 $ModifiedLines += "END`n"
    #             }
    #         }
    #         elseif ($content[$i] -match "^CREATE\s+$FileType") {
    #             $ModifiedLines += $content[$i].replace('CREATE', 'ALTER') + "`n"
    #         }
    #         else {
    #             $ModifiedLines += $content[$i] + "`n"
    #         }
    #     }
    # }
    # else {
    #     $ModifiedLines = $content
    # }


    # $fileName = $_.Name
    # if ($fileName.endswith(".FT.sql")) {
    #     $fileName = $fileName.Replace(".FT.sql",".sql")
    # }

    # Revisar
    # $content | Set-Content -Path (Join-Path -Path $tmpPath -ChildPath $_.Name) 
    # Move-Item -Path (Join-Path -Path $tmpPath -ChildPath $_.Name) -Destination $_.FullName -Force

# Revisar
# Remove-Item -Path $tmpPath