###########################################################################
# Author: Alexis CHEVALLIER
# Date: 2020-10-21
# Last revision date: 2021-04-19
# Revision: -
#    - Added Credentials and domain management, moved export file and log files to different directories
#    - Added files cleanup for files older than 7 days. Added logging and verbosity. Replaced tabs with spaces. (2021-03-02)
#    - Added Write-Log function, moved export result file to variable (2021-03-02)
#    - Added OU loop, modified user loop, added group per user, added username, changed csv delimiter, changed properties (2021-03-01)
#    - Added try catch (2021-02-17)
#    - Added comment header, synopsis, DistinguishedName and Enabled filter on adUsers (2020-11-17)
###########################################################################

<# .SYNOPSIS
    Export AD users with full identities and group membership
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
    It also logs its progression and cleans up its files older that a given time
#>
# Import modules
Import-Module ActiveDirectory

# Import Credentials
$credentials = Import-CliXml user.cred

# Initialize variables
$exportResults = @()
$obj = @()
$date = Get-Date -Format yyyyMMdd
$dateCleanup = -7
$targetDomain = "spldom.local"
$workingDir = "E:\Program Files\Export-ADUsers"
$logDir = "$($workingDir)\log"
$exportDir = "E:\ISP_SNOW_Uploads\Export-ADUsers"
$fileName = "Export_ADUsers"
$exportResultsFilePath = "$($exportDir)\$($date)_-_$($fileName).csv"
$exportResultsCleanupDate = (Get-Date).AddDays($dateCleanup)

$OUs = 'OU=User Accounts,DC=spldom,DC=local'

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
    $logFile = "$logDir\$($date)_-_$($fileName).log"
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

Write-Log "Starting export of AD Users"

try{
	
    # Looping through the OUs
    ForEach($OU in $OUs){
    
        Write-Log "Processing $($OU)"
        		
        #Fetching AD Users per OU
        $adUsers = Get-ADUser -Server $targetDomain `
							-Credential $credentials `
							-Filter * `
							-SearchBase $OU `
							-Properties SAMAccountName, 
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
            $userGroups = (Get-ADPrincipalGroupMembership -Server $targetDomain -Credential $credentials -Identity $adUser |
                        Select-Object -ExpandProperty name) -Join ','
            
            # Creating User.Name variable
            $userName = ("$($adUser.GivenName).$($adUser.Surname)").ToLower()
            
            # Adding info to powershell object
            $obj += [PSCustomObject] @{
                    SAMAccountName     = $adUser.SAMAccountName
                    UserName           = $userName
                    GivenName          = $adUser.GivenName
                    Surname            = $adUser.Surname
                    EmailAddress       = $adUser.EmailAddress
                    OfficePhone        = $adUser.OfficePhone
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
    $exportResults | 
    Export-Csv -Path $($exportResultsFilePath) -Delimiter ';'
    
    #Removing old exports
    Write-Log "Cleaning up older exports"
    Get-ChildItem $exportDir\*$fileName.* | 
    Where-Object { $_.LastWriteTime -lt $exportResultsCleanupDate } | 
    Remove-Item
    
    #Removing old logs
    Write-Log "Cleaning up older logs"
    Get-ChildItem $logDir\*$fileName.* | 
    Where-Object { $_.LastWriteTime -lt $exportResultsCleanupDate } | 
    Remove-Item
    
    Write-Log "Done exporting AD Users"
}
catch {
    
    Write-Log "Error processing" "ERROR"
    Write-Log "$($_)" "ERROR"
    
}
