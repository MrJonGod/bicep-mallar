param environment string 

var location = 'westeurope'
var receivingFunctionAppName = 'tn-temperature-receiver-euwe-func-${environment}'
var sendingFunctionAppName = 'tn-temperature-sender-euwe-func-${environment}'
var keyVaultName = 'tntemperaturekv${environment}'
var storageName = 'tntemperaturest${environment}'
var applicationInsightsName = 'tn-temperature-euwe-appi-${environment}'
var appServicePlanName = 'tn-temperature-euwe-asp-${environment}'
var forecastTopicName = 'tn-temperature-forecast-sbt'
var observationTopicName = 'tn-temperature-observation-sbt'
var topicSubscriptions = [ 'biztalk-sbts' ]

//Existing resource names 
var servicebusName = 't-shared-euwe-sbns-${environment}'
var commonRgName = 't-shared-euwe-rg-${environment}'
var workspaceName = 't-shared-euwe-log-${environment}'
var commonStorageName = 'tsharedst${environment}'

/*******************************************************************************************
* Get the existing log analytics workspace
*******************************************************************************************/
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: workspaceName
  scope: resourceGroup(commonRgName)
}

/******************************************************************************************
* Create topics + subscriptions in service bus namespace and give function app access
*******************************************************************************************/
module forecastServiceBusTopic './sbtopic.bicep' = {
  name: 'create${forecastTopicName}'
  scope: resourceGroup(commonRgName) 
  params: {
    namespaceName: servicebusName
    topicName: forecastTopicName
    sendingFunctionAppPrincipalId: sendingFunctionApp.identity.principalId
    receivingFunctionAppPrincipalId: receivingFunctionApp.identity.principalId
    subscriptions: topicSubscriptions
  }
}

module observationServiceBusTopic './sbtopic.bicep' = {
  name: 'create${observationTopicName}'
  scope: resourceGroup(commonRgName) 
  params: {
    namespaceName: servicebusName
    topicName: observationTopicName
    sendingFunctionAppPrincipalId: sendingFunctionApp.identity.principalId
    receivingFunctionAppPrincipalId: receivingFunctionApp.identity.principalId
    subscriptions: topicSubscriptions
  }
}

/******************************************************************************************
* Create app service plan for the function apps 
*******************************************************************************************/
resource appServicePlan 'Microsoft.Web/serverfarms@2024-11-01' = {
    name: appServicePlanName
    location: location
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
  }

/******************************************************************************************
* Create application insight 
*******************************************************************************************/
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

/*****************************************************************************************
* Create storage for function apps 
******************************************************************************************/
resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageName
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  location: location
}

/******************************************************************************************
* Create Sending Function App  
*******************************************************************************************/
resource receivingFunctionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: receivingFunctionAppName
  kind: 'functionapp'
  location: location
  identity: {
    type: 'SystemAssigned' 
  }
  properties: {
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
    }
    httpsOnly: true
    serverFarmId: appServicePlan.id
  }
}

/*****************************************************************************************
* Create sending function app  
******************************************************************************************/
resource sendingFunctionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: sendingFunctionAppName
  kind: 'functionapp'
  location: location
  identity: {
    type: 'SystemAssigned' 
  }
  properties: {
    siteConfig: {
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
    }
    httpsOnly: true
    serverFarmId: appServicePlan.id
  }
}

/****************************************************************************************
* Create key vault
*****************************************************************************************/
resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenant().tenantId
  }
}

/****************************************************************************************
* Give the function apps read access to the key vault 
*****************************************************************************************/
var secretUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6' //Static value for secret user role, see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

resource roleAssignmentSendingFunctionKeyvault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, keyVaultName, secretUserRoleId, sendingFunctionAppName)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretUserRoleId)
    principalId: sendingFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentReceivingFunctionKeyvault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, keyVaultName, secretUserRoleId, receivingFunctionAppName)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', secretUserRoleId)
    principalId: receivingFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/****************************************************************************************
* Give the funtion apps access to the solution specific storage account 
*****************************************************************************************/
var blobContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Static value for blob contributor role, see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

resource roleAssignmentSendingFunctionBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sendingFunctionAppName, blobContributorRoleId, storageName)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobContributorRoleId)
    principalId: sendingFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentReceivingFunctionBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(receivingFunctionAppName, blobContributorRoleId, storageName)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobContributorRoleId)
    principalId: receivingFunctionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/****************************************************************************************
* Give the function apps access to the common storage
*****************************************************************************************/
module roleAssignmentSendingFunctionBlobCommon './commonstorage.bicep' = {
  name: guid(sendingFunctionAppName, commonStorageName)
  scope: resourceGroup(commonRgName) 
  params: {
    storageName: commonStorageName
    functionAppPrincipalId: sendingFunctionApp.identity.principalId
    functionAppName: sendingFunctionAppName
  }
}

module roleAssignmentReceivingFunctionBlobCommon './commonstorage.bicep' = {
  name: guid(receivingFunctionAppName, commonStorageName)
  scope: resourceGroup(commonRgName) 
  params: {
    storageName: commonStorageName
    functionAppPrincipalId: receivingFunctionApp.identity.principalId
    functionAppName: receivingFunctionAppName
  }
}
