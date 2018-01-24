import-module SLPSLib
$csvpath = "D:\Tmp\Projects\Contopsa\GlenBerry-PROD"
New-Item -Path $csvpath -Name "excel" -ItemType Directory -Force
$excelpath = Join-Path -Path $csvpath -ChildPath "excel"
$csvs = gci -Path $csvpath -Filter *.csv -file
foreach ($csv in $csvs) {
  $filename = $csv.name
  $doc = New-SLDocument -WorkbookName $filename -Path $excelpath -PassThru
  Import-CSVToSLDocument -WorkBookInstance $doc -CSVFile $csv.fullName -AutofitColumns | Save-SLDocument
}