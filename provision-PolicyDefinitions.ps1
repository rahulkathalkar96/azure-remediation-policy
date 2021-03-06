<#
.SYNOPSIS
    Create azure remediation policies definition

.DESCRIPTION
    This script creates azure definitions which are used to auto remediate resources by cloudneeti

.NOTES
    Version:        1.0
    Author:         Cloudneeti
    Creation Date:  06/12/2019

    #PREREQUISITE
    
.EXAMPLE
	
	1. Provision Policy Definitions in Azure subscription
	.\provision-PolicyDefinitions.ps1 -SubscriptionId <Subscription Id>

#>

[CmdletBinding()]
param
(
        # Enter Subscription Id for deployment.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [guid]
        $SubscriptionId
)
# Session configuration
$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Write-Host "Script Execution Started"

# Checking current azure rm context and switching to required subscription
Write-Host "Checking Azure Context"
$AzureContextSubscriptionId = (Get-AzContext).Subscription.Id

If ($AzureContextSubscriptionId -ne $subscriptionId) {
    Write-Host "You are not logged in to subscription" $subscriptionId 
    Try {
        Write-Host "Trying to switch powershell context to subscription" $subscriptionId
        $AllAvailableSubscriptions = (Get-AzSubscription).Id
        if ($AllAvailableSubscriptions -contains $subscriptionId) 
        {
            Set-AzContext -SubscriptionId $subscriptionId 
            Write-Host "Successfully context switched to subscription" $subscriptionId
        }
        else {
            Write-Host "Looks like the" $AzureSubscriptionId "is not present in current powershell context or you don't have access" -ForegroundColor Red
            exit
        }
    }
    catch [Exception] {
        Write-Host "Error occurred during Azure Context switching, Try again." -ForegroundColor Red
        Write-Output $_
        exit
    }
}


write-host "Getting all the definition category"
#Collecting policy categories/directories
$policyDir = "$PSScriptRoot\policies"
$policyDefinitionCategories = Get-ChildItem -Path $policyDir

foreach ($category in $policyDefinitionCategories.Name){
    Write-Host "Inititing policy definition creation from category:"  $category ""  -ForegroundColor Magenta

    $definitions = Get-ChildItem -Path "$policyDir\$category" 
    ForEach($definition in $definitions) {
        $definitionName = $definition.Name
        $definitionPath = "$policyDir\$category\$definitionName"
        $metaDataFilePath = "$definitionPath\metadata.json"
        $definitionMetaData = Get-Content -Raw -Path $metaDataFilePath | ConvertFrom-Json
        write-host "Creating policy definition for policy:" $definitionMetaData.description "" -ForegroundColor Yellow
        $metadata = $definitionMetaData.metadata | ConvertTo-Json

        Try{
            New-AzPolicyDefinition -Name $definitionMetaData.name `
            -DisplayName $definitionMetaData.displayname `
            -description $definitionMetaData.description `
            -Mode $definitionMetaData.mode `
            -Metadata $metadata `
            -Policy "$definitionPath\azurepolicy.rules.json" `
            -Parameter "$definitionPath\azurepolicy.parameters.json"
        }
        catch [Exception]{
            Write-Error $_
        }
    }
    Write-Host "Azure policy created successfully for category:" $category.Name ""-ForegroundColor Green
}

Write-Host "Script execution completed."