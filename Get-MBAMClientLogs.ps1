#requires -Version 3


$LogPath = 'C:\Transfer'

Write-Host "Checking to ensure $LogPath exists, if not creating it"
 
If((Test-Path -Path $LogPath) -ne $true)
{
  New-Item -Path $LogPath -ItemType Container
}

$iLog = $LogPath + "\$($ENV:COMPUTERNAME)_"

[xml]$xmlPath = @"
<QueryList>
    <Query Id='0' Path='System'>
        <Select Path='System'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-BitLocker/BitLocker Management'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-BitLocker/BitLocker Operational'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-Bitlocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-BitLocker-DrivePreparationTool/Admin'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-BitLocker-DrivePreparationTool/Operational'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-MBAM/Admin'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
        <Select Path='Microsoft-Windows-MBAM/Operational'>*[System[Provider[@Name='Microsoft-Windows-BitLocker-API' or @Name='Microsoft-Windows-BitLocker-DrivePreparationTool' or @Name='Microsoft-Windows-BitLocker-Driver' or @Name='Microsoft-Windows-BitLocker-Driver-Performance' or @Name='Microsoft-Windows-MBAM' or @Name='TPM' or @Name='Microsoft-Windows-TPM-WMI']]]</Select>
    </Query>
</QueryList>
"@

Write-Host "Gathering Event Logs from $ENV:COMPUTERNAME"
Get-WinEvent -FilterXml $xmlPath  | Export-Csv -Path $iLog'events.csv'

Write-Host "Gathering FVE Registry Keys from $ENV:COMPUTERNAME"
Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE | Out-File -FilePath $iLog'FVE.reg'

Write-Host "Gathering MBAM Software Registry Keys from $ENV:COMPUTERNAME"
Get-Item -Path HKLM:\Software\Microsoft\MBAM | Out-File -FilePath $iLog'MBAM_SOFT.reg'

Write-Host "Gathering MBAM Policy Registry Keys from $ENV:COMPUTERNAME"
Get-ChildItem -Path HKLM:\Software\Policies\Microsoft\FVE | Out-File -FilePath $iLog'MBAM.reg'

Write-Host "Obtaining Paths to MBAM Web Services on $ENV:COMPUTERNAME"
$SRSE_URI = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('StatusReportingServiceEndpoint')
$KRSE_URI = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('KeyRecoveryServiceEndPoint')

Write-Host "Testing URL for StatusReportingServiceEndpoint on $ENV:COMPUTERNAME"
Invoke-WebRequest -Uri $SRSE_URI -UseDefaultCredentials  | Out-File -FilePath $iLog'SRSE_URI.log'

Write-Host "Testing URL for KeyRecoveryServiceEndpoint on $ENV:COMPUTERNAME"
Invoke-WebRequest -Uri $KRSE_URI -UseDefaultCredentials  | Out-File -FilePath $iLog'KRSE_URI.log'

$keyType = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('OSDriveProtector')
Switch ($keyType)
{
  0 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'Unknown or other protector type'
  }
  1 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'Trusted Platform Module (TPM)'
  }
  2 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'External key'
  }
 
  3 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'Numerical password'
  }
 
  4 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'TPM And PIN'
  }
 
  5  
  {
    Add-Content -Path $iLog'Settings.log' -Value 'TPM And Startup Key'
  }
 
  6 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'TPM And PIN And Startup Key'
  }
 
  7 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'Public Key'
  }
 
  8 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'Passphrase'
  }
 
  9 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'TPM Certificate'
  }
 
  10 
  {
    Add-Content -Path $iLog'Settings.log' -Value 'CryptoAPI Next Generation (CNG) Protector'
  }
}

Write-Host "Getting Group Policy Results from $ENV:COMPUTERNAME"
$args = '/H ' + $iLog + 'GPResults.html' 
Start-Process -FilePath 'C:\Windows\System32\gpresult.exe' -ArgumentList $args -WindowStyle Hidden -Wait

Write-Host "Getting Win32_EncryptableVolume Information from $ENV:COMPUTERNAME"
Get-WmiObject -Class 'Win32_EncryptableVolume' -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' | Out-File -FilePath $iLog'WMI_NS.log'

Compress-Archive -Path c:\transfer\* -CompressionLevel Optimal -DestinationPath c:\transfer\MBAMLogs.zip


$hdr = '*'  * 60
Write-Host $hdr -ForegroundColor Yellow
Write-Host "Directory contents have been archived for you in $LogPath "`n"Please send MBAMLogs.zip to your support engineer for review" -ForegroundColor yellow -BackgroundColor Black
Write-Host $hdr -ForegroundColor Yellow


