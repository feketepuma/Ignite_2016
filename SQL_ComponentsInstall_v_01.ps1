$ComputerName = $ENV:COMPUTERNAME
$DomainName = $ENV:USERDNSDOMAIN

## First get the SQL media root and see if the folder / drive exist, if it does not script will exit
## Give the user two times to get it right before exiting script

$SQL_MediaLocation = Read-Host -Prompt 'What is the location of the SQL installation media (e.g. D:)'
If ((Test-Path -Path $SQL_MediaLocation) -eq $false)
{
	Write-Host 'SQL media not found at that location, please try again'
	$SQL_MediaLocation = Read-Host -Prompt 'What is the location of the SQL installation media (e.g. D:)'
	If ((Test-Path -Path $SQL_MediaLocation) -eq $false)
	{
		Write-Host 'SQL media not found at that location, script will now exit'
		Exit 1001
	}
}

## Removing trailing '\' if it exists for error handling purposes
If ($SQL_MediaLocation.Contains('\'))
{
	$SQL_MediaLocation = $SQL_MediaLocation.Replace('\','')
}

## Second check to see if setup.exe is in the root of the path given, will not do any checks to determine if it
## 	is really SQL media, will assume that if you are trying to install SQL then you will have this.

If ((Test-Path -Path "$SQL_MediaLocation\Setup.exe") -eq $false)
{
	Write-Host 'SQL Server setup.exe does not exist in the path specified, exiting script'
	Exit 1001
}

## Third get the location of the MBAM server setup media, so that we can install MBAM after the SQL server install completes
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
	$MBAM_MediaLocation = $MBAM_MediaLocation.Replace('\','')
}

## Fourth check to see if the path given contains "MBAMServersetup.exe" file if not script will exit
If ((Test-Path -Path "$MBAM_MediaLocation\MBAMServerSetup.exe") -eq $false)
{
	Write-Host 'MBAM Server components installation not found in the path specified, exiting script.'
	Exit 1002
}

## Fifth fix the firewall to allow for SQL Server Reporting Services and Database Services to be accepted
Write-Host 'Creating firewall rules to allow for SQL Server Reporting Services and Database Services'
Write-Host 'The firewall rule is only for the local subnet, so the MBAM server is on a different subnet you'
Write-Host 'will need to edit the firewall rule prior to installation of MBAM server components on the web server'
Start-Process -FilePath 'C:\Windows\System32\netsh.exe' -ArgumentList 'advfirewall firewall add rule name=SQLPort dir=in protocol=tcp action=allow localport=1433 remoteip=localsubnet profile=Domain'
Start-Process -FilePath 'C:\Windows\System32\netsh.exe' -ArgumentList 'advfirewall firewall add rule name=ReportingServer dir=in protocol=tcp action=allow localport=443 remoteip=localsubnet profile=Domain'

## Sixth ask for SQL information for installation
## There will be no error handling on these variables and the script will error on the SQL install if any are wrong
$SQL_ServiceAccountName = Read-Host 'What is the service account for SQL - NO SPACES (e.g. DOMAIN\Username)'
$SQL_ServiceAccountPass = Read-Host 'What is the password for the service account (e.g. TempPassword)'
$SQL_AdminsADGroup = Read-Host 'What is the AD group that will be SQL SysAdmins - NO SPACES (e.g. DOMAIN\MBAM_SQL_Admins)'
$SQL_DBPath = Read-Host 'What is the path you want the SQL Databases to be located at (e.g. S:\MSSQL_DB)'
$SQL_TempDBPath = Read-Host 'What is the path you want the SQL Temp DB to be located at (e.g. S:\MSSQL_TP)'
$SQL_LogPath = Read-Host 'What is the path you want the SQL Logs to be located at (e.g. S:\MSSQL_LG)'

## Putting all the SQL variables together for the SQL installation on the system
$SQLSource = "$SQL_MediaLocation\setup.exe"
$SQL_SvcAcct = "/SQLSVCACCOUNT=$SQL_ServiceAccountName /SQLSVCPASSWORD=$SQL_ServiceAccountPass"
$SQL_SysAdmin = "/SQLSYSADMINACCOUNTS=$SQL_AdminsADGroup"
$SQL_Features = '/FEATURES=SQLEngine,RS,ADV_SSMS,SSMS,Conn'
$SQL_DBPath = "/SQLUSERDBDIR=$SQL_DBPath"
$SQL_TPPath = "/SQLTEMPDBLOGDIR=$SQL_TempDBPath"
$SQL_LGPath = "/SQLUSERDBLOGDIR=$SQL_LogPath"
$SQL_BaseCommands = '/ACTION=INSTALL /INSTANCENAME=MSSQLServer /QS /NPENABLED=0 /TCPENABLED=1 /AGTSVCACCOUNT="NT AUTHORITY\Network Service" /IACCEPTSQLSERVERLICENSETERMS'
$SQL_Install_Args = $SQL_BaseCommands + ' ' + $SQL_SvcAcct + ' ' + $SQL_SysAdmin + ' ' + $SQL_Features + ' ' + $SQL_DBPath + ' ' + $SQL_TPPath + ' ' + $SQL_LGPath

## Installing SQL, this script will not determine if SQL installed successfully that will be manually validated by the end user
Write-Host 'Beginning the SQL installation, the script will pause after this for validation SQL installed successfully'
Write-Host ' --- Also you will need to configure SSRS with the SSL certificate after this and before continuing'
Start-Process -FilePath $SQLSource -ArgumentList $SQL_Install_Args -Wait

Write-Host 'Once you have validated the SQL is installed and that SSRS is using an SSL certificate then'
Write-Host 'Press any key to continue ...'
$x = $host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

Write-Host 'Starting MBAM Server components installation, this is not configuring the DB or Reports yet'
$MBAM_Install_Args = '/silent /log C:\Windows\Logs\MBAM_Install.log CEIPENABLED=FALSE OPTIN_FOR_MICROSOFT_UPDATES=True'
Start-Process -FilePath "$MBAM_MediaLocation\MBAMServersetup.exe" -ArgumentList $MBAM_Install_Args -Wait

Write-Host 'MBAM Server components installed, please validate by checking for an icon on the start menu before continuing'
Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

## Asking for MBAM Server components information before continuing
$MBAM_ReadWriteAccount = Read-Host 'What is the MBAM Read/Write account username (e.g. DOMAIN\svc-mbam-dbrw)'
$MBAM_ReportUsersGroup = Read-Host 'What is the MBAM Reporting user group (e.g. DOMAIN\MBAM_Reporting_Users)'
$MBAM_ReadOnlyAccount = Read-Host 'What is the MBAM Read Only account username (e.g. DOMAIN\svc-mbam-dbro)'
$MBAM_RecoveryDBName = Read-Host 'What is the Recovery Database Name (e.g. MBAM_Recovery)'
$MBAM_ComplianceDBName = Read-Host 'What is the Compliance Database Name (e.g. MBAM_Compliance)'

Import-Module 'C:\Program Files\Microsoft BitLocker Administration and Monitoring\WindowsPowerShell\Modules\Microsoft.MBAM\Microsoft.MBAM.psd1'

# Enable compliance and audit database
Enable-MbamDatabase -AccessAccount "$MBAM_ReadWriteAccount" -ComplianceAndAudit -ConnectionString "Data Source=$ComputerName + '.' + $DomainName;Integrated Security=True" -DatabaseName $MBAM_ComplianceDBName -ReportAccount "$MBAM_ReadOnlyAccount"

# Enable recovery database
Enable-MbamDatabase -AccessAccount "$MBAM_ReadWriteAccount" -ConnectionString "Data Source=$ComputerName + '.' + $DomainName;Integrated Security=True" -DatabaseName "$MBAM_RecoveryDBName" -Recovery

# Enable report feature
Enable-MbamReport -ComplianceAndAuditDBConnectionString "Data Source=$ComputerName + '.' + $DomainName;Initial Catalog=MBAM_Compliance;Integrated Security=True" -ComplianceAndAuditDBCredential (Get-Credential -UserName "$MBAM_ReadOnlyAccount" -Message 'MBAM Read Only Account Credentials') -ReportsReadOnlyAccessGroup "$MBAM_ReportUsersGroup"


# SIG # Begin signature block
# MIITSAYJKoZIhvcNAQcCoIITOTCCEzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2E7e5vDQ2SQlinvQAsaWao0g
# WLaggg3kMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFANUBeI0hwuUPy1wuKqGdCVx
# D0UGMA0GCSqGSIb3DQEBAQUABIIBAANc7ujFSw1SeKl2nuBfey8L/OZxnL1JBUdK
# dPmU2w6DtAHQ6UbY8iJbObijTJI3KSbVsfY/CriNggpQ6GhlIayNt1ggk378sF2c
# Kfz4zijULvEn8qCZzY6uqndhc019/tuEOp7IMGC0bkEJSf33qBLMEtLyYEqTLzUI
# 5h1Gtn0l7c0gVHJrjJCcX4CV5e0+fieHe+3DM7t/TxNsx4OK1U+gaChRd0xkjlkE
# TdouY0vrAR4TtEc7nMee5hi7mmONNVzyu4EjwufFBMUTvFae5aevaY/aeAvyDisG
# XVpns8Q64OQ+4ymJedcDqRxMwvnPODGrW8J8fgpD/AaSaqQcXY6hggKiMIICngYJ
# KoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMAkGBSsOAwIaBQCggf0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwNzE2MjEw
# OTQyWjAjBgkqhkiG9w0BCQQxFgQUk7w4BNZ6m/+4Srk+yADaB5wDJiMwgZ0GCyqG
# SIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+rYfWDkJaVBQsAJJxQKTPseTBsMFak
# VDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYG
# A1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadklz7x
# +EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIBACXiwcV8W6BhuwanrqM3iNIwIGm0
# d1c7VpZb+N2juTzJWTYyjp553vNc6htrvFKPnPlH9cg74YH4EruC8mZPCctlfjBO
# 4nF47hmT5X3OhstpBHjSDIdaX4atdPwo1biBYjeEEiL7TuCVnc6ZIzZGMo/NnxTv
# x3Oqq2q7GcznV2HqLYqH0VL85N/pXCvmYFqNNYVAo9e3QUWr9PcWPIaTDaWETSlS
# z/9CyXTb/iJ4+VJiRguUsVlr3V562XCS+Xp82BXQR9DxxhYNWt0+G3MML9bDeHM8
# YYIsYreStFACpaeXg1SaRWVzTsQkloH9zRmVZKanhc7hxHWi4+TmWuBng0A=
# SIG # End signature block
