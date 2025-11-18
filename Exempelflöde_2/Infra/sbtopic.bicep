param namespaceName string
param topicName string
param sendingFunctionAppPrincipalId string
param receivingFunctionAppPrincipalId string 
param subscriptions array

/*******************************************************************************************
* Get existing service bus namespace
********************************************************************************************/
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = {
  name: namespaceName
}

/*******************************************************************************************
* Create topic in existing namespace 
********************************************************************************************/
resource topic 'Microsoft.ServiceBus/namespaces/topics@2024-01-01' = {
  name: topicName
  parent: serviceBusNamespace
}

/*******************************************************************************************
* Create topic subscription
********************************************************************************************/
resource topicSubscriptions 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2024-01-01' = [for item in subscriptions: {
  name: item 
  parent: topic
}]

/*******************************************************************************************
* Give the funtion app receive access to the service bus namespace topic subscription
********************************************************************************************/
var serviceBusDataReceiverRoleId = '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' //Static value for sb data receiver role (https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
resource roleAssignmentReceiverServiceBus 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusDataReceiverRoleId, topic.id)
  scope: topic
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataReceiverRoleId)
    principalId: receivingFunctionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*******************************************************************************************
* Give the funtion app send access to the service bus namespace topic
********************************************************************************************/
var serviceBusDataSenderRoleId = '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' //Static value for sb data sender role (https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
resource roleAssignmentSenderServiceBus 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(serviceBusDataSenderRoleId, topic.id)
  scope: topic
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', serviceBusDataSenderRoleId)
    principalId: sendingFunctionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
