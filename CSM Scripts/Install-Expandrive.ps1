##########################################################
# Software installation script
# Author: Alexis CHEVALLIER
# Date: 20190917
# ToDo: 
##########################################################

<#

.SYNOPSIS
This Powershell script is used to deploy an application and its
user configuration files from a web server. It is also used to
uninstall said program. Here, Expandrive is installed.

.DESCRIPTION
The script will fetch packages and files via Invoke-WebRequest and
install them.

.EXAMPLE
Install Expandrive and copy user files
./Install-Expandrive.ps1 [Start-Install]

Uninstall Expandrive, user files will remain
./Install-Expandrive.ps1 Start-Uninstall

Copy only user files, no installation
./Install-Expandrive.ps1 Copy-UserFiles

.LINK
https://git.intranet.ses/acheval/powershell/blob/master/CSM%20Scripts/Install-Expandrive.ps1

#>

[CmdletBinding()]
Param(
    [ValidateSet('Start-Install', 'Start-Uninstall', 'Copy-UserFiles')]
    [string]$option = 'Start-Install'
)


# Variables
$baseUrl = 'http://lubtzcsmwus01.csm.goe.ses/' #To change if US or Lux
$software = 'Expandrive'
$version = '6' # To have some kind of version control on deployed MSIs
$package = 'ExpanDrive_Setup_6.4.5.exe'
$files = 'expandrive6.favorites.js',
         'ExpanDrive6.ExpanDriveLicense'
$dir = 'C:\Temp\'
$userDir = "$($env:APPDATA + "\" + $software)" 
$userInstall = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match $software }
$computerInstall = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -match $software }

function Start-Install {
# Tests if C:\Temp exists, if not, create it
    If ( -Not (Test-Path $dir)){
        New-Item -ItemType Directory -Path $dir
    }
    
    # Check if the software exists either in the HKCU Uninstall keys (per user install) or in the HKLM Uninstall keys (Computer install)  
    # If the software is not installed, fetch it from the web server and install it, otherwise, skip
    If ( -Not $userInstall -or $computerInstall ) {
        Write-Warning "$software is not installed";
        Write-Host "Downloading $software from $($baseUrl + $software)"
    
        # Dirty (?) solution to make an actual path from the variables
        $pdlUrl = "$($baseUrl + $software + "/" + $version + "/" + $package)"
        $pdlPath = "$($dir + $package)"
        Try {
            Invoke-WebRequest $pdlUrl -OutFile $pdlPath
        } catch {
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
            break
        }        
        # Once fetched, we run the package through Start-Process
        Write-Host "Installing $software from $pdlPath"
        $process = Start-Process $pdlPath -PassThru
        # The WaitForExit() method replaces the -Wait flag of Start-Process, because once the software is installed, 
        # Start-Process still considers it as running, even though the original process stopped, which blocks the installation
        # until the forked process is killed.
        $process.WaitForExit()
        # Test if the software is running and kills it if it is. 
        # Tasklist is used to find the expandrive PID per user. 
        # Get-Process cannot give the process' username unless ran as administrator. If an admin runs the script with get-process and stop-process, all existing processes would stop.
        # Select-Object -Skip 3 is used to remove the 3 header lines of tasklist, we split the rest of the output on the whitespaces, then we select column 1
        $isRunning =  tasklist /S $env:COMPUTERNAME /FI "USERNAME eq $env:USERNAME" /FI "IMAGENAME eq $software*"  | Select-Object -Skip 3 | ForEach-Object {($_ -split '\s+')[1]}
        If ( $isRunning ) {
        Write-Host "Stopping $software"
        Start-Sleep -seconds 10
            ForEach ($proc in $isRunning){
                Try{
                    Stop-Process $($proc) -PassThru
                } catch {
                    Write-Host "Couldn't stop process $proc, ExitCode: $($proc.ExitCode)"
                    break
                }
            }
        }
        # In case of no error
        If ($($process.ExitCode) -eq 0) {
            Write-Host "$software has been installed"
            Write-Host "Removing the package in $pdlPath"
            Remove-Item $pdlPath
        } else {
        # In case of errors
            Write-Warning "Something wrong happend during the installation. Exit Code: $($process.ExitCode)"
            Remove-Item $pdlPath 
            break
        }
    } else {
        Write-Host $software "is already installed, skipping";
    }

    Copy-UserFiles

}

# Runs the uninstallers
function Start-Uninstall {  
    If ( $userInstall ) {
        Write-Host "User installation found. Uninstalling"
        #Fetches the users registry keys to uninstall the software
        Try{
            Start-Process "powershell.exe" -ArgumentList "$($userInstall.QuietUninstallString)" -Wait -PassThru
            Remove-Item $userDir
            Remove-Item $($env:LOCALAPPDATA + "\" + $software)
        } catch {
            Start-Process "powershell.exe" -ArgumentList "$($userInstall.UninstallString)" -Wait -PassThru
        }      
    } elseif ( $computerInstall ) {
        Write-Host "Computer installation found. Uninstalling"
        # Fetches the computer registry keys to uninstall the software.
        # For some reason, the uninstall string in the registry is actually running with the /I flag instead of the /X.
        # To avoid errors, the msiexec is stripped from the command too. It is passed in the start-process instead.
        $uninstallProgram = $computerInstall.UninstallString + " /passive /promptrestart" -replace "msiexec.exe","" -replace "/I","/X "
        Start-Process "msiexec.exe" -ArgumentList "$uninstallProgram" -Wait -PassThru
    } else {
        Write-Host "No $software installation detected"
    }
}


function Copy-UserFiles {

    # Tests if the software directory exists under AppData\Roaming
    If ( -Not (Test-Path $userDir)){
        Write-Warning "$userDir not present. Creating"
        New-Item -ItemType Directory -Path $userDir
    } else {
        Write-Host "$userDir exists, skipping"
    }
    
    # Loop to test config files 
    ForEach ($file in $files) {
        $localFile = "$($userDir + "\" + $file)"
        $fdlUrl = "$($baseUrl + $software + "/" + $version + "/" + $file)"
        # Case if the file path doesn't exists
        If ( -Not (Test-Path $localFile) )  {
            Write-Warning "$file not present in $userDir"
            Write-Host "Downloading $file from $($baseUrl + $software)"
            $fdlPath = "$($userDir + "\" + $file)"
            Try {
                $request = Invoke-WebRequest $fdlUrl -OutFile $fdlPath
            } catch {
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                break
            }
        # Case if the file path exists
        } else {
            Write-Host "$file is present in $userDir"
            Write-Host "Checking if existing $file is correct"
            $tdlPath = "$($dir + $file)"
            # Downloads files for comparison
            Try {
                $request = Invoke-WebRequest $fdlUrl -OutFile $tdlPath
            } catch {
                Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                break
            }
            # Hash existing and new file
            $hashRef = (Get-FileHash $tdlPath -Algorithm SHA256).Hash # New file
            $hashDif = (Get-FileHash $localFile -Algorithm SHA256).Hash # Existing file
            Compare-Object -ReferenceObject $hashRef -DifferenceObject $hashDif | ForEach-Object { If ($_.Sideindicator -ne " ==") {$dif+=1} }
            # If hashes are different, force to move the new file to
            # overwrite the existing one, and resets the dif variable
            If ( $dif -ne 0) {
                Write-Warning "$localFile is different from the source file, overwriting"
                Move-Item -Path $tdlPath -Destination $localFile -Force
                Set-Variable -Name dif -Value 0
            # If hashes are the same, delete the new file and resets the dif variable
            } else {
                Write-Host "Current $file looks alright, skipping."
                Remove-Item $tdlPath
                Set-Variable -Name dif -Value 0
            }
        } 
    }
}

# Enables the switches to install, uninstall the application, or copy the user files 
Switch ($option) {
    'Start-Install' { Start-Install }
    'Start-Uninstall' { Start-Uninstall }
    'Copy-UserFiles' { Copy-UserFiles }
}

