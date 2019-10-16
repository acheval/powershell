foreach($file in (Get-ChildItem *.xls)) {
    $newname = $file.FullName -replace '\.xls$', '.csv'
    $ExcelWB = new-object -comobject excel.application
    $Workbook = $ExcelWB.Workbooks.Open($file.FullName)
    $Workbook.SaveAs($newname,6)
    $Workbook.Close($false)
    $ExcelWB.quit()
  }
