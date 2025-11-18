//Sätts i Deploy.ps1
param location string 
param appServicePlanName string 

//Sätts i parameters.<env>.json 
param skuName string 
param skuCapacity int 

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location 
  sku: {
    name: skuName
    capacity: skuCapacity
  }
}
