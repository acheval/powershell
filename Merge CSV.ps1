Get-ChildItem *.csv |
 ForEach-Object {Import-csv $_.Name -Header Time,Ins,Outs |
 Select-object -First 1 -Last 98} |
 Group-Object Time |
 Select @{name="Time";expression={$_.Name}}, @{name="Ins and outs";expression={($_.Group | % {$_.Ins + ',' +  $_.Outs}) -join ','}} |
 Export-Csv ".\$(Get-Date -f yyyy-MM) - Doors.csv"
