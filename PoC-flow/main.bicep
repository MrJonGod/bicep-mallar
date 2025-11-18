// Parameters for naming components according to Namnstandard.txt
@description('Customer abbreviation (e.g., sx, abg, lejon)')
param customerPrefix string

@description('Domain/technical area (e.g., int, dataplatform, finance)')
param domain string

@description('Function describing the resource purpose (e.g., shared, demo, api)')
param function string

@description('Optional subfunction for more detailed categorization')
param subfunction string = ''

@description('Environment: d (dev), t (test), q/s (qa/staging), p (prod)')
@allowed(['d', 't', 'q', 's', 'p'])
param environment string

@description('Azure region for deployment (e.g., swedencentral, westeurope)')
param location string = 'swedencentral'

// Region abbreviations according to Microsoft standard
// https://learn.microsoft.com/en-us/azure/backup/scripts/geo-code-list
var regionAbbreviations = {
  swedencentral: 'sdcr'
  swedensouth: 'sdsr'
  westeurope: 'we'
  northeurope: 'ne'
}

var regionShort = contains(regionAbbreviations, location) ? regionAbbreviations[location] : 'we'

// Build naming components
var functionPart = subfunction != '' ? '${function}-${subfunction}' : function
var baseNameWithRegion = '${customerPrefix}-${domain}-${functionPart}-${regionShort}-${environment}'
var baseName = '${customerPrefix}-${domain}-${functionPart}-${environment}'

// Resource names according to Namnstandard.txt
var resourceGroupName = '${baseName}-rg'
var logAnalyticsName = '${baseNameWithRegion}-log'
var applicationInsightsName = '${baseNameWithRegion}-appi'

// Storage account naming with special handling (max 24 chars, lowercase only, no hyphens)
var storageBaseName = '${customerPrefix}${domain}${replace(functionPart, '-', '')}${environment}st'
var storageName = length(storageBaseName) > 24 ? substring(storageBaseName, 0, 24) : storageBaseName

// Validate storage name length
// Note: This validation happens at deployment time
@description('Storage account name must be 24 characters or less')
var storageNameValidation = length(storageBaseName) <= 24 ? true : false

/*******************************************************************************************
* Create Log Analytics Workspace
*******************************************************************************************/
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

/*******************************************************************************************
* Create Application Insights
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

/*******************************************************************************************
* Create Storage Account
*******************************************************************************************/
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

/*******************************************************************************************
* Outputs
*******************************************************************************************/
output resourceGroupName string = resourceGroupName
output storageAccountName string = storageAccount.name
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output applicationInsightsName string = applicationInsights.name
output storageNameLength int = length(storageName)
output storageNameValidation bool = storageNameValidation
