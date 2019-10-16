$software = 'nettime',
            'tardis',
            'ntp'
$userInstall = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* 
$computerInstall = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    
foreach ($soft in $software){ 
    $userInstall = $userInstall | Where-Object { $_.DisplayName -match $soft }
    $computerInstall = $computerInstall | Where-Object { $_.DisplayName -match $soft }
    If ( $userInstall -or $computerInstall ){
        Write-Host "$soft is present"
    } else {
        Write-Host "$soft is not present"
    }
}
