$ComputerName = $ENV:COMPUTERNAME
$DomainName = $ENV:USERDNSDOMAIN

Write-Host 'Ensure you have downloaded the ASP .Net MVC 4 Components prior to execution of the script'
Write-Host 'Download location: http://www.microsoft.com/en-us/download/details.aspx?id=30683'
Write-Host 'File must be called AspNetMVC4Setup.exe'

## First get the location of the MBAM server setup media, so that we can install MBAM after the SQL server install completes
$MBAM_MediaLocation = Read-Host -Prompt 'What is the location of the MBAM server components installation file (e.g. C:\Temp)'
If ((Test-Path -Path $MBAM_MediaLocation) -eq $false)
{
	Write-Host 'MBAM media not found at that location, please try again'
	$MBAM_MediaLocation = Read-Host -Prompt 'What is the location of the MBAM installation media (e.g. C:\Temp)'
	If ((Test-Path -Path $MBAM_MediaLocation) -eq $false)
	{
		Write-Host 'MBAM media not found at that location, script will now exit'
		Exit 1002
	}
}

## Removing trailing '\' if exists for error handling purposes
If ($MBAM_MediaLocation.Contains('\'))
{
	$MBAM_MediaLocation = $MBAM_MediaLocation.Replace('\', '')
}

## Second check to see if the path given contains "MBAMServersetup.exe" file if not script will exit
If ((Test-Path -Path "$MBAM_MediaLocation\MBAMServerSetup.exe") -eq $false)
{
	Write-Host 'MBAM Server components installation not found in the path specified, exiting script.'
	Exit 1002
}

## Third get the location of the AspNet MVC 4a, so that we can install it on the server
$ASPNet_MediaLocation = Read-Host -Prompt 'What is the location of the AspNetMVC 4 components installation file (e.g. C:\Temp)'
If ((Test-Path -Path $ASPNet_MediaLocation) -eq $false)
{
	Write-Host 'ASPNetMVC 4 components media not found at that location, please try again'
	$ASPNet_MediaLocation = Read-Host -Prompt 'What is the location of the AspNetMVC 4 components installation file (e.g. C:\Temp)'
	If ((Test-Path -Path $ASPNet_MediaLocation) -eq $false)
	{
		Write-Host 'ASPNetMVC 4 components not found at that location, script will now exit'
		Exit 1002
	}
}

## Removing trailing '\' if exists for error handling purposes
If ($ASPNet_MediaLocation.Contains('\'))
{
	$ASPNet_MediaLocation = $ASPNet_MediaLocation.Replace('\', '')
}

## Forth check to see if the path given contains "AspNetMVC4Setup.exe" file if not script will exit
If ((Test-Path -Path "$ASPNet_MediaLocation\AspNetMVC4Setup.exe") -eq $false)
{
	Write-Host 'ASPNetMVC 4 components installation not found in the path specified, exiting script.'
	Exit 1002
}

Write-Host 'Installing ASP .NET MVC 4 Components on the system'
Start-Process -FilePath "$ASPNet_MediaLocation\AspNetMVC4Setup.exe" -ArgumentList '/s' -Wait

Write-Host 'Adding IIS and the components required for MBAM Installation of the Helpdesk and SelfService Portals'
$Features = 'Web-Server', 'Web-WebServer', 'Web-Common-Http', 'Web-Default-Doc', 'Web-Static-Content', 'Web-Security', 'Web-Filtering', 'Web-Windows-Auth', 'Web-App-Dev', 'Web-Net-Ext45',
'Web-Asp-Net45', 'Web-ISAPI-Ext', 'Web-ISAPI-Filter', 'Web-Mgmt-Tools', 'Web-Mgmt-Console', 'NET-WCF-Services45', 'NET-WCF-HTTP-Activation45', 'NET-WCF-TCP-Activation45',
'WAS', 'WAS-Process-Model', 'WAS-NET-Environment', 'WAS-Config-APIs'
Add-WindowsFeature -Name $Features

Write-Host 'Installing MBAM Server components'
$MBAM_Args = '/silent /log C:\Windows\Logs\MBAM_Install.log CEIPENABLED=FALSE OPTIN_FOR_MICROSOFT_UPDATES=True'
Start-Process -FilePath "$MBAM_MediaLocation\MBAMServerSetup.exe" -ArgumentList $MBAM_Args -Wait

## Outputing all the certificates in the local computer store for the user to select which one is right
Get-ChildItem -Path Cert:\LocalMachine\My
Write-Host ''
Write-Host 'Find the certificate thumbprint of the SSL certificate you wish to use for MBAM Web Service'
Write-Host 'Paste this thumbprint in the next line'
$CertificateTP = Read-Host 'What is the certificate thumbprint to use'
Write-Host ''
$MBAM_CompanyName = Read-Host 'What is the company name and/or department that you want to display on Self-Service Portal (e.g. Contoso IT)'
$SQL_ServerName = Read-Host 'What is the SQL Server FQDN (e.g. sql01.contoso.com)'
$SQL_RptURL = Read-Host 'What is the SQL Reporting Services URL (e.g. https://sql01.contoso.com/ReportServer)'
$SQL_CompDBName = Read-Host 'What is the MBAM Compliance DB Name (e.g. MBAM_Compliance)'
$SQL_RecvDBName = Read-Host 'What is the MBAM Recovery DB Name (e.g. MBAM_Recovery)'
$MBAM_Helpdesk = Read-Host 'What is the AD Group for MBAM Helpdesk (e.g. MBAM_Helpdesk_Users)'
$MBAM_AdvHelpdesk = Read-Host 'What is the AD Group for MBAM Advanced Helpdesk (e.g. MBAM_Adv_Helpdesk_Users'
$MBAM_Rpt = Read-Host 'What is the AD Group for the MBAM Reporting Users (e.g. MBAM_Reporting_Users)'
$MBAM_DBRW = Get-Credential -UserName "CONTOSO\svc-mbam-dbrw" -Message 'MBAM Read Write User Account Credentials'

Import-Module 'C:\Program Files\Microsoft BitLocker Administration and Monitoring\WindowsPowerShell\Modules\Microsoft.MBAM\Microsoft.MBAM.psd1'

Write-Host 'Installing MBAM onto the server'
# Enable agent service feature
Enable-MbamWebApplication -AgentService -Certificate (Get-ChildItem cert:\LocalMachine\My\$CertificateTP)
-ComplianceAndAuditDBConnectionString "Data Source=$SQL_ServerName;Initial Catalog=$SQL_CompDBName;Integrated Security=True" -HostName "$ComputerName + '.' + $DomainName" -InstallationPath 'C:\inetpub'
-Port 443 -RecoveryDBConnectionString "Data Source=$SQL_ServerName;Initial Catalog=$SQL_RecvDBName;Integrated Security=True" -TpmLockoutAutoReset
-WebServiceApplicationPoolCredential $MBAM_DBRW

# Enable administration web portal feature
Enable-MbamWebApplication -AdministrationPortal -AdvancedHelpdeskAccessGroup "$MBAM_AdvHelpdesk" -Certificate (Get-ChildItem cert:\LocalMachine\My\$CertificateTP)
-ComplianceAndAuditDBConnectionString "Data Source=$SQL_ServerName;Initial Catalog=$SQL_CompDBName;Integrated Security=True" -HelpdeskAccessGroup "$MBAM_Helpdesk" -HostName "$ComputerName + '.' + $DomainName"
-InstallationPath 'C:\inetpub' -Port 443 -RecoveryDBConnectionString "Data Source=$SQL_ServerName;Initial Catalog=$SQL_RecvDBName;Integrated Security=True" -ReportsReadOnlyAccessGroup "$MBAM_Rpt"
-ReportUrl "$SQL_RptURL" -VirtualDirectory 'HelpDesk' -WebServiceApplicationPoolCredential $MBAM_DBRW

# Enable self service web portal feature
Enable-MbamWebApplication -Certificate (Get-ChildItem cert:\LocalMachine\My\$CertificateTP) -CompanyName "$MBAM_CompanyName"
-ComplianceAndAuditDBConnectionString "Data Source=$SQL_ServerName;Initial Catalog=$SQL_CompDBName;Integrated Security=True" -DisableNoticePage -HelpdeskUrlText 'Contact Helpdesk or IT department.'
-HostName "$ComputerName + '.' + $DomainName" -InstallationPath 'C:\inetpub' -Port 443 -RecoveryDBConnectionString "Data Source=$SQL_ServerName; Initial Catalog=$SQL_RecvDBName; Integrated Security=True"
-SelfServicePortal -VirtualDirectory 'SelfService' -WebServiceApplicationPoolCredential $MBAM_DBRW


# SIG # Begin signature block
# MIITSAYJKoZIhvcNAQcCoIITOTCCEzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAWhdQfSCbDH7LMZdXzv0BSpr
# Wtqggg3kMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BJ8wggOHoAMCAQICEhEh1pmnZJc+8fhCfukZzFNBFDANBgkqhkiG9w0BAQUFADBS
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UE
# AxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAeFw0xNjA1MjQwMDAw
# MDBaFw0yNzA2MjQwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8wHQYDVQQKExZHTU8g
# R2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxTaWduIFRTQSBmb3Ig
# TVMgQXV0aGVudGljb2RlIC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal+oTDYUDFRrVZUjtC
# oi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1AcjzyCXenSZKX1GyQ
# oHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFFWbIub2Jd4NkZrItX
# nKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7spTj1Tk7Om+o/SWJMV
# TLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5crCpGTkqUPqp0Dw6
# yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAOBgNVHQ8BAf8EBAMC
# B4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0OBBYEFNSihEo4Whh/
# uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0hZuw3WrWFKnBMA0G
# CSqGSIb3DQEBBQUAA4IBAQCPqRqRbQSmNyAOg5beI9Nrbh9u3WQ9aCEitfhHNmmO
# 4aVFxySiIrcpCcxUWq7GvM1jjrM9UEjltMyuzZKNniiLE0oRqr2j79OyNvy0oXK/
# bZdjeYxEvHAvfvO83YJTqxr26/ocl7y2N5ykHDC8q7wtRzbfkiAD6HHGWPZ1BZo0
# 8AtZWoJENKqA5C+E9kddlsm2ysqdt6a65FDT1De4uiAO0NOSKlvEWbuhbds8zkSd
# wTgqreONvc0JdxoQvmcKAjZkiLmzGybu555gxEaovGEzbM9OuZy5avCfN/61PU+a
# 003/3iCOTpem/Z8JvE3KGHbJsE2FUPKA0h0G9VgEB7EYMIIFJTCCBA2gAwIBAgIQ
# CvxB3V5898sRPV/gaYADjzANBgkqhkiG9w0BAQsFADByMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5n
# IENBMB4XDTE2MDEwNzAwMDAwMFoXDTE3MDExMTEyMDAwMFowYjELMAkGA1UEBhMC
# VVMxDjAMBgNVBAgTBVRleGFzMQ8wDQYDVQQHEwZGcmlzY28xGDAWBgNVBAoTD1dp
# bGxpYW0gU2xheXRvbjEYMBYGA1UEAxMPV2lsbGlhbSBTbGF5dG9uMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2+vV0MRL/YqGiVzrTzYPTEywB9hJu50x
# 2KWbHNLoWOxGSzMqP9Njo1UFKNwBEkHqZW/HyIEuOnw7VIzi69z7cw6SP6L0eEyJ
# aiVJ7xYvVmFamKCBh/0HxuS3tql9AZyCp2C9k7ODhy9QCTMoyxwtZIejdNWkyXYd
# BaMp5dcIdL1Sv7N27DlpNaOyyEzfqyAhFnYVh/A1GeCaiG1sJLHIGciYFBk3r2+r
# BRhXdpqrDkFv5yPOpl3ImHgDYQJHmpo837a+aey930w/CID2kTbrreY17ne5elRJ
# GULqY7Oum4krHgSOTvNxWIdTVlLJUI+2adgMULKJa2QPELMvBciCUwIDAQABo4IB
# xTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHQYDVR0OBBYE
# FHYXykGZ3H0cE4vqC5UY7jIlXlTuMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAK
# BggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYvaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwTAYDVR0gBEUwQzA3
# BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQu
# Y29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgwdjAkBggrBgEFBQcwAYYY
# aHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUFBzAChkJodHRwOi8vY2Fj
# ZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNzdXJlZElEQ29kZVNpZ25p
# bmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAQEASU3y6iVz
# NwQQE7k1FHqCAeWo6Bd/o0KIaeEpNKDgiDNsUKDOKIV689T2chLcosD3/tGHkcGG
# WoD4ZtUBXRE9iHvIH4FeD0Qfo+iwU8Il+7vv//f5huX71ukVnCTsAWkUivLJBVhU
# 1qU7tYnnYQNeNL7mniHkwfjoHGLZP4ZRl6zhrgYSKNfSXuKzb77lonDe1o1N0kUQ
# dDd4390R6BaQcKGeCccIJ9cxcyDiOlmpOBrXy3s0yTe6VoRgREG2cdZnt8iIT5Dc
# djs7115PStXojbSuMCGDUxAIJe7529yyIY4oH26Zck6FhY+CP5O+fWWj4bhSyyhi
# Pdy7v+41sFHYnzGCBM4wggTKAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0ECEAr8
# Qd1efPfLET1f4GmAA48wCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFK4IIvgq3HSRgYaFORipyDxG
# SUE9MA0GCSqGSIb3DQEBAQUABIIBAEHVXwi91TSsr3qBb8L9jW1webohQZFlTs7r
# lXr9Kv2kC0Awz1x8UYo0Kf+w51/eGcCeeXDsRCqdETYP1jrW/qyKRB4jd40kGB8c
# HZKlneFdZB738RraKchgDu4RRMPZGb9l2BCbMnjUywYD0kp+QT66efJua1uR2PdT
# 5kFnCatKAd7gybQMBlfMxCnadHKwZ9Li04k8rysCbt81+SHRgM9/3lfVIlET2ypz
# OKBi76S1OX04zjoYkJPLWCVpRLu39CUr0VHimpGYbR0KRIBFEpBQ94GyQTmARwBc
# 3SdbSBfB0LrEM8XK3dOVg83KLy6EWRs5c2EZ+C2r1OD7AH2QaCOhggKiMIICngYJ
# KoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMAkGBSsOAwIaBQCggf0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwNzE3MDIz
# OTE4WjAjBgkqhkiG9w0BCQQxFgQUnkMY1L1qx8yfUI4h6bztmlMUzUkwgZ0GCyqG
# SIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+rYfWDkJaVBQsAJJxQKTPseTBsMFak
# VDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYG
# A1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadklz7x
# +EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIBAHb1kiMzXRsa5VsD8gmv3N8Tu6BX
# VpTChGTbjnjJJFJ5l9DW10AfhgtKQsNq/MqTtv8mJgDNxmB3YefB7uZAqsqKtfwD
# +rCoYvGpVNs+/X4HgKEXpxPMtouh78FwBG6vnHwyuuvz4CbDRDAl0xgSM9tA8HCk
# p26tpr8pB2L+7vAI9+7jFoxMwAuhA31Pr40NnRLyzYQbCdSwQTbi+ISTasmFrkpg
# gLYb1a4h3qNzkQd1H83TwUCGQbPowoHjC1RWETp9f2JINjJfes9j7FPzMY/X/res
# wyeg+N3/3LmflGFThxjpa560lgVEKmbV8zbgcYM/OuB0E9Nt/RfQB8mJVvc=
# SIG # End signature block
