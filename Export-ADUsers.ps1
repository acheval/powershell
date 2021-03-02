###########################################################################
# Author: Alexis CHEVALLIER
# Date: 2020-10-21
# Last revision date: 2021-03-02
# Revision: - Added Write-Log function, moved export result file to variable
#	- Added OU loop, modified user loop, added group per user, added username, changed csv delimiter, changed properties (2021-03-01)
#	- Added try catch (2021-02-17)
#	- Added comment header, synopsis, DistinguishedName and Enabled filter on adUsers (2020-11-17)
###########################################################################

<# .SYNOPSIS
	Export enabled AD users with full identities and group membership
.DESCRIPTION
	Fetches and exports AD Users within given OU :
	- SAMAccountName
	- DisplayName
	- GivenName
	- Surname
	- EmailAddress
	- OfficePhone
	- Description
	- UserAccountControl
	- whenChanged
.RETURNVALUE
	This script returns a timestamped CSV file under the current working dir.
#>
# Import modules
Import-Module ActiveDirectory

# Initialize variables
$exportResults = @()
$obj = @()
$date = get-date -f yyyyMMdd
$workingDir = get-location
$exportResultsFile = "$workingdir\$($date)_-_Export_ADUsers.csv"

$OUs = 'OU=External Resources,DC=servitia,DC=internal',
	   'OU=Internal Resources,DC=servitia,DC=internal'

Function Write-Log {
    [CmdletBinding()]
    Param(
	[Parameter(Mandatory=$True)]
    [string]
    $message,

	[Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]
    $level = "INFO",
	
    [Parameter(Mandatory=$False)]
    [string]
    $logFile = "$workingdir\$($date)_-_Export_ADUsers.log"
    )

    $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $line = "$stamp $level $message"
    If($logFile) {
        Add-Content $logFile -Value $line
    }
    Else {
        Write-Output $line
    }
}

try{
	
	# Looping through the OUs
	ForEach($OU in $OUs){
	
		Write-Log "Processing $($OU)"
		
		#Fetching AD Users per OU
		$adUsers = Get-ADUser -Filter * -SearchBase $OU -Properties SAMAccountName, 
																	DisplayName,
																	GivenName,
																	Surname,
																	EmailAddress,
																	OfficePhone,
																	Description,
																	UserAccountControl,
																	whenChanged
																	
		# Iterating through the users
		ForEach ($adUser in $adUsers) {
			
			# Fetching groups
			$userGroups = (Get-ADPrincipalGroupMembership -Identity $adUser |
						Select-Object -ExpandProperty name) -Join ','
			
			# Creating User.Name variable
			$userName = ("$($adUser.GivenName).$($adUser.Surname)").ToLower()
			
			# Adding info to powershell object
			$obj += [PSCustomObject] @{
					SAMAccountName     = $adUser.SAMAccountName
					UserName           = $userName
					GivenName		   = $adUser.GivenName
					Surname			   = $adUser.Surname
					EmailAddress	   = $adUser.EmailAddress
					OfficePhone		   = $adUser.OfficePhone
					Description        = $adUser.Description
					UserAccountControl = $adUser.UserAccountControl
					MemberOf           = $userGroups
					LastChanged        = $adUser.whenChanged
			}
				
		}
		
		Write-Log "Done processing $($OU)"
		
	}
	
	# Adding object to exportResults
	Write-Log "Done processing OUs"
	$exportResults = $obj
	
	#Exporting Results
	Write-Log "Exporting results"
	$exportResults | Export-Csv -Path $($exportResultsFile) -Delimiter ';'
}
catch {
	
	Write-Log "Error processing" "ERROR"
	Write-Log "$($_)" "ERROR"

}
