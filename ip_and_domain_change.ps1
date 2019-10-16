# Logging
$DesktopPath= [Environment]::GetFolderPath("Desktop")
$Stamp = (Get-Date).toString("yyyyMMdd-HHmmss")
Start-Transcript -Append -Path $DesktopPath\$Stamp"_script.log"

#Input the details
    #Network details

Write-Host "Enter the new IPv4 address of the machine:"
    [ipaddress]$IPAddress= Read-Host 
    $IPAddress = $IPAddress.IPAddressToString
    if ([bool] ($IPAddress -as [ipaddress])){
        Write-Host $IPAddress "will be used"
    } else {
        Write-Host -ForegroundColor Red "Invalid IP Address"
        break
    }


Write-Host "Enter the mask bits:"
    [ValidateRange(1,32)]$MaskBits = Read-Host

Write-Host "Please enter the defaut gateway's IPv4 Address:" 
    [ipaddress]$GatewayIPAddress = Read-Host 
    $GatewayIPAddress = $GatewayIPAddress.IPAddressToString
    if ([bool] ($GatewayIPAddress -as [ipaddress])){
        Write-Host $GatewayIPAddress "will be used"
    } else {
        Write-Host -ForegroundColor Red "Invalid IP Address"
        break
    }

Write-Host "Please enter the DNS IPv4 Address:"
[ipaddress]$DNSIPAddress = Read-Host 
    $DNSIPAddress = $DNSIPAddress.IPAddressToString

$IPType = "IPv4"

    #Domain details

[string]$LocalCredential= Read-Host -Prompt "Input a local admin username"

[string]$DomainCredential= Read-Host -Prompt "Input a domain user capable of integrating new computers"

[string]$NewDomain = Read-Host -Prompt "Input the machine's new domain"

[string]$OUPath= Read-Host -Prompt "Input the Distinguished Name OU Path"

# Select the adapter
Get-NetAdapter | ? {$_.Status -eq "up"}
$NetworkInterfaceID= Read-Host -Prompt "Enter the interface index of the NIC you want to modify"

# Review the input
Write-Host "IP Address:" $IPAddress"/"$MaskBits
Write-Host "Gateway:" $GatewayIPAddress
Write-Host "DNS Server:" $DNSIPAddress
Write-Host "To be set on Interface :" $NetworkInterfaceID
Write-Host "Computer will be renamed with local user:" $LocalCredential
Write-Host "To be integrated in:" $NewDomain
Write-Host "With domain user:" $DomainCredential
Write-Host "Under the" $OUPath "OU"

[void](Read-Host "Press Enter to continue")

# Remove any existing IP, gateway from our ipv4 adapter
If ((Get-NetIPConfiguration -InterfaceIndex $NetworkInterfaceID).IPv4Address.IPAddress) {
    Remove-NetIPAddress -InterfaceIndex $NetworkInterfaceID -AddressFamily $IPType -Confirm:$false
}

If ((Get-NetIPConfiguration -InterfaceIndex $NetworkInterfaceID).Ipv4DefaultGateway) {
    Remove-NetRoute -InterfaceIndex $NetworkInterfaceID -AddressFamily $IPType -Confirm:$false
}

New-NetIPAddress –InterfaceIndex $NetworkInterfaceID -AddressFamily $IPType –IPAddress $IPAddress –PrefixLength $MaskBits -DefaultGateway $GatewayIPAddress

Set-DnsClientServerAddress -InterfaceIndex $NetworkInterfaceID -ServerAddresses $DNSIPAddress

Start-Sleep -s 10

$FQDNNameHost= (Resolve-DnsName $IPAddress).NameHost
    $DNSNameHost= $FQDNNameHost.split(".")[0]
    
Add-Computer -LocalCredential $LocalCredential@$env:ComputerName -NewName $DNSNameHost -Credential $DomainCredential@$NewDomain -DomainName $NewDomain -Options AccountCreate -OUPath $OUPath -Confirm -Restart