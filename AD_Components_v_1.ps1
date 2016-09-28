## Prompting the user for SQL User Credentials
$sql01_creds = (Get-Credential -UserName 'DOMAIN\svc-sql01' -Message 'SQL Server Account Credentials').Password # P@55w0rd@1986
$mbamdbrw_creds = (Get-Credential -UserName 'DOMAIN\svc-mbam-dbrw' -Message 'MBAM Read Write User Account Credentials').Password # In@M33t1ng
$mbamdbro_creds = (Get-Credential -UserName 'DOMAIN\svc-mbam-dbro' -Message 'MBAM Read Only Account Credentials').Password # P@55w0rd@3085

## Creating Users that will be placed in the Default Users Container
Write-Host 'Creating svc-sql01 User Account'
New-ADUser -Name 'svc-sql01' -AccountPassword $sql01_creds -Description 'SQL01 Service User Account' -DisplayName 'SQL Service Account - SQL01' -Enabled $true -SamAccountName 'svc-sql01' -LogonWorkstations 'sql01'
Write-Host 'Creating svc-mbam-dbrw User Account'
New-ADUser -Name 'svc-mbam-dbrw' -AccountPassword $mbamdbrw_creds -Description 'MBAM IIS Application Pool Account' -DisplayName 'MBAM IIS Application Pool' -Enabled $true -SamAccountName 'svc-mbam-dbrw'
Write-Host 'Creating svc-mbam-dbro User Account'
New-ADUser -Name 'svc-mbam-dbro' -AccountPassword $mbamdbro_creds -Description 'MBAM Read-Only Account' -DisplayName 'MBAM Read Only' -Enabled $true -SamAccountName 'svc-mbam-dbro'

## Creating Groups that will be placed in the Default Users Container
Write-Host 'Creating SQL Server Administrator Group'
New-ADGroup -DisplayName 'MBAM SQL Server Admins' -Description 'User has full rights to SQL Server for MBAM' -GroupScope Global -GroupCategory Security -Name 'MBAM_SQL_Admins' -SamAccountName 'MBAM_SQL_Admins'
Write-Host 'Creating MBAM Reporting Users Group'
New-ADGroup -DisplayName 'MBAM Reporting Users' -Description 'Group has access to MBAM Reports' -GroupCategory Security -GroupScope Global -Name 'MBAM_Reporting_Users' -SamAccountName 'MBAM_Reporting_Users'
Write-Host 'Creating MBAM Advanced Help Desk Users Group'
New-ADGroup -DisplayName 'MBAM Advanced Helpdesk Users' -Description 'Group has access to MBAM Recovery Keys' -GroupCategory Security -GroupScope Global -Name 'MBAM_Adv_Helpdesk_Users' -SamAccountName 'MBAM_Adv_Helpdesk_Users'
Write-Host 'Creating MBAM Helpdesk Users Group'
New-ADGroup -DisplayName 'MBAM Helpdesk Users' -Description 'Group has access to MBAM Recovery Keys' -GroupCategory Security -GroupScope Global -Name 'MBAM_Helpdesk_Users' -SamAccountName 'MBAM_Helpdesk_Users'

## Prompting the user to add at least one user to each of the groups
$user_MBAMSQLAdmin = Read-Host 'Please provide one user that is a member of the SQL Server Administrators Group (e.g. Administrator)'
$user_MBAMReports = Read-Host 'Please provide one user that is a member of the MBAM Reports Group (e.g. Administrator)'
$user_MBAMAdvHelp = Read-Host 'Please provide one user that is a member of the MBAM Advanced Helpdesk Group (e.g. Administrator)'
$user_MBAMHelp = Read-Host 'Please provide one user that is a member of the MBAM Helpdesk Group (e.g. Administrator)'

Write-Host 'Adding User to the SQL Admins group'
Add-ADGroupMember 'MBAM_SQL_Admins' "$user_MBAMSQLAdmin"
Write-Host 'Adding User to the MBAM Reporting group'
Add-ADGroupMember 'MBAM_Reporting_Users' "$user_MBAMReports"
Write-Host 'Adding User to the MBAM Advanced Helpdesk group'
Add-ADGroupMember 'MBAM_Adv_Helpdesk_Users' "$user_MBAMAdvHelp"
Write-Host 'Adding User to the MBAM Helpdesk group'
Add-ADGroupMember 'MBAM_Helpdesk_Users' "$user_MBAMHelp"


# SIG # Begin signature block
# MIITSAYJKoZIhvcNAQcCoIITOTCCEzUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0rt/8sZxtu+0vEZFIsonK7w6
# RVyggg3kMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# MAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPEeegOaTLThwifk1UeZx82r
# TXc2MA0GCSqGSIb3DQEBAQUABIIBALDtfcqunIXLUqVV+wcHwXRU1EEurXoRhdJZ
# wqxLg4dHfi9H4e6m4gqbDlGnE6AcKpiLQ76v7aTXJ+nNlVx2xBAEkvWhnt7xKkaB
# u0mprfuTu8RGf6XMDz8m0GO0ftodOyr4e6tbKgFvBwh1Ma6KLtJg2stdNnXXJ0j5
# JO8aZ5y7rT6wurIwtP25XHsZxXYIH/L5saNQIh1kgbqFIH9dkFfuUsFer9HPDqSy
# plK3xaagLJ4U6le3Kn+J8pDNg3qaI2UxijFGi5ACp+qkiFV4KWzeex6ScGOhCL0X
# ZilMimQR9a0f25S99ttn0X9jDnJnKSxNBAvC94mNN2QQMj2zL0qhggKiMIICngYJ
# KoZIhvcNAQkGMYICjzCCAosCAQEwaDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBp
# bmcgQ0EgLSBHMgISESHWmadklz7x+EJ+6RnMU0EUMAkGBSsOAwIaBQCggf0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTYwNzE2MjEw
# MzE3WjAjBgkqhkiG9w0BCQQxFgQUuKav0esEffdu3jVv1yeBjZhulmowgZ0GCyqG
# SIb3DQEJEAIMMYGNMIGKMIGHMIGEBBRjuC+rYfWDkJaVBQsAJJxQKTPseTBsMFak
# VDBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYG
# A1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMgISESHWmadklz7x
# +EJ+6RnMU0EUMA0GCSqGSIb3DQEBAQUABIIBAK1wHFA8CGWsw59JPGt5cFhDIBsi
# WTf2VSXLmsgYu3OlMc8JE//2A5o/U5KBRc16Wr/r4PBJ7yYkusKUXsJX5CH5hP+m
# QqJkdDIMfGSGhNHO5h6A9ikLTaGtMw2q22TXbb1PgsQWkDSJy8+XyeSHdL9CB22U
# LuH8rsr/AfzFJL2WZom2uMR1Xy/+inejJyKvkxx7d/Z7CVVmOp9LHj29+RdIcHDW
# ZcC6An18P+Iw6z9ykOhMNG8QxqpW2CyebJAW8afJF7ICeZ0b5CbgdrgeZaSKdE7l
# S5MZKMLM94eCs6LkkIBSkAFv6udFO1ogzhsCZg3X6a6BTwFOeeRsCt8YB3Q=
# SIG # End signature block
