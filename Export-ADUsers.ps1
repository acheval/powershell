Import-Module ActiveDirectory

#Initialize variables
$exportResults = @()
$date = get-date -f yyyyMMdd

#Fetching AD Users

$adUsers = Get-ADUser -Properties * -Filter "name -like '*'" | 
            Select-Object SAMAccountName,
                DisplayName,
                Description,
                UserAccountControl, 
                @{N='MemberOf';E={$_.memberof}} 

#Creating the Custom PSObject and iterating through the users

ForEach ($adUser in $adUsers) {

    ForEach ($group in $adUser.MemberOf){
        (Get-ADGroup -Identity $group).memberof
        }

    $obj = [PSCustomObject] @{
           SAMAccountName     = $adUser.SAMAccountName
           DisplayName        = $adUser.DisplayName
           Description        = $adUser.Description
           UserAccountControl = $adUser.UserAccountControl
           MemberOf           = $adUser.MemberOf
           }

$exportResults += $obj

}

#Exporting Results

$exportResults | Export-Csv "C:\Temp\$($date)_-_Export_ADUsers.csv"