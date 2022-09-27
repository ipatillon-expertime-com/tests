Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install powershell-core

$command = @'
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
if (!(Get-Module "DataGateway")) { "Installing Module DataGateway" ; Install-Module -Name DataGateway }

$securePassword = "<<Secure Key>>" | ConvertTo-SecureString -AsPlainText -Force
$ApplicationId ="<<Your Client/Application ID>>"
$Tenant = "<<Your Tenant ID>>"
$installerID = "<<Your ServicePrincipal's Managed Application Object ID>>"
$GatewayName = "<<Your GatewayName>>"
$RecoverKey = <<Your RecoveryKey>>| ConvertTo-SecureString -AsPlainText -Force;
$userIDToAddasConnection = "<<User to add Object ID GUID>>"
$groupIDToAddasAdmin = "<<Groups Object ID GUID to add as admin>>"

#Gateway Login
Connect-DataGatewayServiceAccount -ApplicationId $ApplicationId -ClientSecret $securePassword -Tenant $Tenant

#Set Gateway Installer
Set-DataGatewayInstaller -PrincipalObjectIds $installerID -Operation Add -GatewayType Resource

#Installing Gateway 
Install-DataGateway -AcceptConditions 

#Configuring Gateway
$GatewayDetails = Add-DataGatewayCluster -Name $GatewayName -RecoveryKey $RecoverKey -OverwriteExistingGateway

#We can restrict what data sources users have access to.
$dsTypes = New-Object 'System.Collections.Generic.List[Microsoft.PowerBI.ServiceContracts.Api.DatasourceType]'
$dsTypes.Add([Microsoft.PowerBI.ServiceContracts.Api.DatasourceType]::Sql)

#Reference: https://docs.microsoft.com/en-us/powershell/module/datagateway/add-datagatewayclusteruser?view=datagateway-ps#parameters

#Add User as Admin
Add-DataGatewayClusterUser -GatewayClusterId $GatewayDetails.GatewayObjectId -PrincipalObjectId $groupIDToAddasAdmin -AllowedDataSourceTypes $null -Role Admin
Add-DataGatewayClusterUser -GatewayClusterId $GatewayDetails.GatewayObjectId -PrincipalObjectId $userIDToAddasConnection -AllowedDataSourceTypes $dsTypes -Role ConnectionCreator

'@

$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

&"C:\Program Files\PowerShell\7\pwsh.exe" -encodedcommand $encodedCommand
