#requires -Version 3
param
(
	[Parameter(Mandatory = $true)]
	[ValidateScript({
			If ((Test-Path -Path $_) -eq $false)
			{
				$false
			}
			Else
			{
				$true
			}
		})]
	[string]$LogPath	
)


$rootLog = Join-Path -Path $LogPath -ChildPath "$ENV:COMPUTERNAME`-"

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
Get-WinEvent -FilterXml $xmlPath | Export-Csv -Path $rootLog'ExportedEvents.csv' -NoTypeInformation
$ErrorEvents = Import-Csv -Path $rootLog'ExportedEvents.csv' | Where-Object { $_.LevelDisplayName -ne 'Information' }
Write-Host "You have a total of $($ErrorEvents.Count) events that are Errors or Warnings"
$ErrorEvents | Export-Csv -Path $rootLog'ExportedErrorEvents.csv' -NoTypeInformation

Write-Host "Gathering FVE Registry Keys from $ENV:COMPUTERNAME"
Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE | Out-File -FilePath $rootLog'FVE.reg'

Write-Host "Gathering MBAM Software Registry Keys from $ENV:COMPUTERNAME"
Get-Item -Path HKLM:\Software\Microsoft\MBAM | Out-File -FilePath $rootLog'MBAM_SOFT.reg'

Write-Host "Gathering MBAM Policy Registry Keys from $ENV:COMPUTERNAME"
Get-ChildItem -Path HKLM:\Software\Policies\Microsoft\FVE | Out-File -FilePath $rootLog'MBAM.reg'

Write-Host "Getting Bitlocker Disk Information from $ENV:COMPUTERNAME"
Get-BitLockerVolume | Export-Csv -Path $rootLog'BitlockerVolume.csv' -NoTypeInformation

Write-Host "Getting TPM Information from $ENV:COMPUTERNAME"
Get-Tpm | Export-Csv -Path $rootLog'TPMStatus.csv' -NoTypeInformation

Write-Host "Obtaining Paths to MBAM Web Services on $ENV:COMPUTERNAME"
$SRSE_URI = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('StatusReportingServiceEndpoint')
$KRSE_URI = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('KeyRecoveryServiceEndPoint')

Write-Host "Testing URL for StatusReportingServiceEndpoint on $ENV:COMPUTERNAME"
Invoke-WebRequest -Uri $SRSE_URI -UseDefaultCredentials -ErrorAction SilentlyContinue | Out-File -FilePath $rootLog'SRSE_URI.log'

Write-Host "Testing URL for KeyRecoveryServiceEndpoint on $ENV:COMPUTERNAME"
Invoke-WebRequest -Uri $KRSE_URI -UseDefaultCredentials -ErrorAction SilentlyContinue | Out-File -FilePath $rootLog'KRSE_URI.log'

$keyType = (Get-Item -Path HKLM:\Software\Policies\Microsoft\FVE\MDOPBitLockerManagement).GetValue('OSDriveProtector')
Switch ($keyType)
{
  0 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'Unknown or other protector type'
  }
  1 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'Trusted Platform Module (TPM)'
  }
  2 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'External key'
  }
 
  3 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'Numerical password'
  }
 
  4 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'TPM And PIN'
  }
 
  5  
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'TPM And Startup Key'
  }
 
  6 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'TPM And PIN And Startup Key'
  }
 
  7 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'Public Key'
  }
 
  8 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'Passphrase'
  }
 
  9 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'TPM Certificate'
  }
 
  10 
  {
    Add-Content -Path $rootLog'Settings.log' -Value 'CryptoAPI Next Generation (CNG) Protector'
  }
}

Write-Host "Getting Group Policy Results from $ENV:COMPUTERNAME"
$args = '/H ' + $rootLog + 'GPResults.html' 
Start-Process -FilePath 'C:\Windows\System32\gpresult.exe' -ArgumentList $args -WindowStyle Hidden -Wait

Write-Host "Getting Win32_EncryptableVolume Information from $ENV:COMPUTERNAME"
Get-WmiObject -Class 'Win32_EncryptableVolume' -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' | Out-File -FilePath $rootLog'WMI_NS.log'

$hdr = '*' * 75
Write-Host $hdr
Write-Host "Please compress the logs contained at $LogPath and submit them for review"
Write-Host $hdr