setup-azuredevops.ps1

#Create Service Principal and assign Owner role to Tenant root scope ("/")
$servicePrincipal = New-AzADServicePrincipal -Role Owner -Scope / -DisplayName AzOps

#Prettify output to print in the format for AZURE_CREDENTIALS to be able to copy in next step.
$servicePrincipalJson = [ordered]@{
    clientId = $servicePrincipal.ApplicationId
    displayName = $servicePrincipal.DisplayName
    name = $servicePrincipal.ServicePrincipalNames[1]
    clientSecret = [System.Net.NetworkCredential]::new("", $servicePrincipal.Secret).Password
    tenantId = (Get-AzContext).Tenant.Id
    subscriptionId = (Get-AzContext).Subscription.Id
} | ConvertTo-Json
#Write-Output $servicePrincipalJson
$escapedServicePrincipalJson = $servicePrincipalJson.Replace('"','\"')
Write-Output $escapedServicePrincipalJson



########################################
# Configure the AzureAD directory role #
########################################

#Install the Module *If Required*
Install-Module -Name "AzureAD" -Verbose -Force -AllowClobber #Do this in PowerShell as admin
Import-Module -Name "AzureAD" -Verbose -Force

#Connect to Azure Active Directory
$AzureAdCred = Get-Credential
Connect-AzureAD -Credential $AzureAdCred

#If you have MFA enabled use these lines instead for interactive AzureAD login that supports MFA
$tenantId = (Get-AzContext).Tenant.Id
Connect-AzureAD -TenantId $tenantID


#Get AzOps Service Principal from Azure AD
$aadServicePrincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq 'AzOps'"

#Get Azure AD Directory Role
#$DirectoryRole = Get-AzureADDirectoryRole -Filter "DisplayName eq 'Directory Readers'"

$DirectoryRole = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Directory Readers"} 

if ($DirectoryRole -eq $NULL) {
    Write-Output "Directory Reader role not found. This usually occurs when the role has not yet been used in your directory"
    Write-Output "As a workaround, try assigning this role manually to the AzOps App in the Azure portal"
}
else {
    
    #Add service principal to Directory Role
    Add-AzureADDirectoryRoleMember -ObjectId $DirectoryRole.ObjectId -RefObjectId $aadServicePrincipal.ObjectId
}