$IPType = "IPv4"
# Select the adapter
Get-NetAdapter | ? {$_.Status -eq "up"}

Write-Host "Enter the interface index of the NIC you want to get network info from:"
[int]$NetworkInterfaceID= Read-Host 

#Domain details

Write-Host "Input a local admin username:"
[string]$LocalUsername= Read-Host

Write-Host "Enter the Password for" $LocalUsername ":"
$LocalPassword= Read-Host -AsSecureString 

Write-Host "Input a domain user capable of integrating new computers:"
[string]$DomainUsername= Read-Host 

Write-Host "Enter the Password for" $DomainUsername ":"
$DomainPassword= Read-Host -AsSecureString 

Write-Host "Input the machine's new domain"
[string]$NewDomain = Read-Host 

Write-Host "Input the Distinguished Name OU Path"
[string]$OUPath= Read-Host 

#Username formatting

$LocalUsername= $env:COMPUTERNAME+'\'+$LocalUsername
$LocalCredential= New-Object System.Management.Automation.PsCredential($LocalUsername,$LocalPassword)

$DomainUsername= $DomainUsername+'@'+$NewDomain
$DomainCredential= New-Object System.Management.Automation.PsCredential($DomainUsername,$DomainPassword)

#DNS 

## Fetch host IP Address
$IPAddress= (Get-NetIPConfiguration -InterfaceIndex $NetworkInterfaceID).IPv4Address.IPAddress

## Fetch DNS Server IP Address
$DNSServer=(Get-DnsClientServerAddress -InterfaceIndex $NetworkInterfaceID -AddressFamily $IPType).ServerAddresses
Start-Sleep -s 3


## Grab FQDN and split it to DNS Name
$FQDNNameHost= (Resolve-DnsName $IPAddress -Server $DNSServer).NameHost
    $DNSNameHost= $(($FQDNNameHost.split(".")[0]).ToString().ToUpper())

#Summary
Write-Host "====================================================================="
Write-Host "Network data will be pulled from Interface :" (Get-NetIPConfiguration -InterfaceIndex $NetworkInterfaceID).InterfaceAlias
Write-Host "Local user:" $LocalUsername
Write-Host "Computer will be renamed:" $DNSNameHost
Write-Host "To be integrated in:" $NewDomain
Write-Host "With domain user:" $DomainUsername
Write-Host "Under the" $OUPath "OU"

[void](Read-Host "Press Enter to continue")

# AD

## Rename Computer
Rename-Computer -LocalCredential $LocalCredential -NewName $DNSNameHost -Confirm -verbose

## Add Computer to Domaun
Add-Computer -Credential $DomainCredential -DomainName $NewDomain -Options AccountCreate,JoinWithNewName -OUPath $OUPath -Confirm -Restart -verbose
