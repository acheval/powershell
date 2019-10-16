# Clear the $errvar variable
$errvar.clear() ; 

Get-CimInstance -ComputerName (Get-Content .\ADComputers.txt) -ClassName win32_Product -ErrorVariable +ErrVar -ErrorAction SilentlyContinue | Where-Object {$_.Name -match "Office.*2010"} | Select-Object PSComputerName, Name, PackageName, InstallDate | Sort-Object PSComputerName | Export-Csv .\Office.csv ;

#Export the computername and its error message for all connection error
$Errvar | Select-Object OriginInfo,Exception | Sort-Object OriginInfo | Out-File .\Unavailable_Machines.txt`