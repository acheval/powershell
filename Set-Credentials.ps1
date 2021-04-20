###########################################################################
# Author: Alexis CHEVALLIER
# Date: 2021-04-19
# Last revision date: 2021-04-19
# Revision: -
#    -
###########################################################################

<# .SYNOPSIS
    Simple script to export username and encrypted password as secure string for scripts to use
	
.DESCRIPTION
	You MUST run this script with the user that will use these credentials. If you create them with another user,
	you will not be able to use them.
	Make sure to update the file ACLs afterwards so only the user who created it can read it.
.RETURNVALUE
    This script returns a single xml file under the current working dir.
#>

Write-Host -ForegroundColor Red -BackgroundColor Black "Read the Description inside the script before proceeding"
Read-Host "Press any key to continue..." 

$credentials = Get-Credential 
$credentials | Export-CliXml user.cred
