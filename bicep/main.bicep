@description('The location into which your Azure resources should be deployed.')
param location string = resourceGroup().location

@description('Select the type of environment you want to provision. Allowed values are Production and Dev.')
@allowed([
  'prod'
  'dev'
])
param environmentType string

// @description('A unique suffix to add to resource names that need to be globally unique.')
// @maxLength(13)
// param resourceNameSuffix string = uniqueString(resourceGroup().id)

// Define the names for resources.
//var appServiceFrontEndAppName = 'app-fe-eus-${environmentType}-tiq-01'
var appServiceBackEndAppName = 'app-be-eus-${environmentType}-tiq-01'
var appServicePlanName = 'plan-customapps'
var functionServicePlanName = 'plan-azure-funcions'
// var apiGatewayName = 'agw-customapps'
// var azureServiceBusName = 'sb-customapps-eus-${environmentType}-tiq-01'
// var customAppsVnetName = 'vnet-customapps'
var functionAppName = 'func-eus-dev-01'
var storageAccountName = 'steus${environmentType}'
// var logAnalyticsWorkspaceName = 'log-${resourceNameSuffix}'
// var applicationInsightsName = 'appi-customapps'

// Define the SKUs for each component based on the environment type.
var environmentConfigurationMap = {
  prod: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 1
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  dev: {
    appServicePlan: {
      sku: {
        name: 'F1'
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_GRS'
      }
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// resource appServiceFrontEndApp 'Microsoft.Web/sites@2022-09-01' = {
//   name: appServiceFrontEndAppName
//   location: location
//   kind: 'app'
//   properties: {
//     serverFarmId: appServicePlan.id
//     httpsOnly: true
//     siteConfig: {
//       linuxFxVersion: 'node|18'
//     }
//     // siteConfig: {
//     //   appSettings: [
//     //     {
//     //       name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
//     //       value: applicationInsights.properties.InstrumentationKey
//     //     }
//     //     {
//     //       name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
//     //       value: applicationInsights.properties.ConnectionString
//     //     }       
//     //   ]
//     // }
//   }
// }

resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: functionServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  properties: {
    reserved: true
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].storageAccount.sku
}

resource appServiceBackEndApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceBackEndAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'node|18'
    }
    // siteConfig: {
    //   appSettings: [
    //     {
    //       name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    //       value: applicationInsights.properties.InstrumentationKey
    //     }
    //     {
    //       name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    //       value: applicationInsights.properties.ConnectionString
    //     }       
    //   ]
    // }
  }
}

// resource apiGateway 'Microsoft.Network/applicationGateways@2022-11-01'= {
//   name: apiGatewayName
//   location:location
//   properties: {
//     sku: {
//       capacity: 1
//       name: 'Standard_Small'
//       tier: 'Standard'
//     }
// }
// }

// resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01'= {
//   name: azureServiceBusName
//   location: location
// }

// resource customAppsVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
//   name: customAppsVnetName
//   location:location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         '10.0.0.0/16'
//       ]
//     }
//     subnets: [
//       {
//         name: 'backendSubnet'
//         properties: {
//           addressPrefix: '10.0.2.0/24'
//         }
//       }
//     ]
//   }
// }



resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'node|18'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
      ]
    }
  }
}

// resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
//   name: logAnalyticsWorkspaceName
//   location: location
// }

// resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
//   name: applicationInsightsName
//   location: location
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//     Request_Source: 'rest'
//     Flow_Type: 'Bluefield'
//     WorkspaceResourceId: logAnalyticsWorkspace.id
//   }
// }



//output appServiceAppHostName string = appServiceApp.properties.defaultHostName
