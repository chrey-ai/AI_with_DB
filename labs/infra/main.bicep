
targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('PostgreSQL user name for database authentication.')
param pgUserName string = 'tdadmin'

@secure()
@description('PostgreSQL user password for database authentication.')
param pgUserPassword string

@description('Authentication type for PostgreSQL server. Allowed values: EntraOnly or Password.')
@allowed([
  'EntraOnly'
  'Password'
])
param pgAuthType string = 'Password'

var tags = {
  'azd-env-name': environmentName
}
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}



// PostgreSQL server
module postgres './pg.bicep' = {
  name: 'postgres'
  scope: rg
  params: {
    name: 'pg-${resourceToken}'
    location: location
    tags: tags
    authType: pgAuthType
    dbUserName: pgUserName
    dbUserPassword: pgUserPassword
    databaseNames: [ 'testdb' ]
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    allowAllIPsFirewall: true
  }
}

// Outputs for PostgreSQL
output POSTGRES_HOST string = postgres.outputs.POSTGRES_DOMAIN_NAME
output POSTGRES_DATABASE string = 'testdb'
output POSTGRES_USER string = pgUserName


module cosmosdb './cdb.bicep' = {
  name: 'cosmosdb'
  scope: resourceGroup('rg-${environmentName}')
  params: {
    name: 'cosdb-${resourceToken}'
    location: location
    tags: tags
  }
}
