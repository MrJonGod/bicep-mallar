param storageName string
param functionAppPrincipalId string
param functionAppName string

/***************************************************************
* Get the existing archive storage account 
***************************************************************/
resource archiveStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageName
}

/**************************************************
* Give the funtion app access to the storage account 
***************************************************/
var blobContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' //Static value for blob contributor role, see https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
resource roleAssignmentArchiveBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionAppName, blobContributorRoleId, storageName)
  scope: archiveStorageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobContributorRoleId)
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
