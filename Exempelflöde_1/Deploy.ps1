param(
     [Parameter(Mandatory)]
     [ValidateSet("dev", "test", "prod")]
     $env
)

if ($env -eq "test") {
    $subscription = "GUID"  
}
elseif ($env -eq "prod") {
    $subscription = "GUID" 
}
else {
    #must be dev 
    $subscription = "GUID"  
}

$environmentShort = $env.Substring(0, 1)
$envParamFile = "parameters.$env.json"
$customerAbbrevation = "test" #antagligen är test redan taget - sätt till ngt random
$location = "swedencentral"
$domain = "int" 
$function = "shared"
$subfunction = "appserviceplan"
$rgName = "$customerAbbrevation-$domain-$function-$subfunction-$environmentShort-rg"
$appServicePlanName = "$customerAbbrevation-$domain-$function-$subfunction-$environmentShort-asp"

$deploymentNumber = Get-Random -Maximum 10000
$deploymentName = "$domain-$function-$env-$deploymentNumber"

#Sätt rätt subscription beroende på miljö 
az account set --subscription $subscription
$rgExists = az group exists --name $rgName 

#Skapa resursgruppen om den inte redan finns
if ($rgExists -ne $true) {
    az group create `
    --name $rgName `
    --location $location `
}

#Skapa resterande resurser
az deployment group create `
    --name $deploymentName `
    --resource-group $rgName `
    --template-file main.bicep `
    --parameters $envParamFile `
    --parameters `
        location=$location `
        appServicePlanName=$appServicePlanName `
