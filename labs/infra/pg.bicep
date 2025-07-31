// Bicep module to deploy an Azure Database for PostgreSQL server with user authentication
// Reference: https://learn.microsoft.com/en-us/azure/postgresql/single-server/quickstart-create-server-database-azure-resource-manager-template

@description('Name of the PostgreSQL server.')
param name string

@description('Location for the PostgreSQL server.')
param location string

@description('Tags to apply to the server.')
param tags object = {}

@description('Authentication type for PostgreSQL server. Allowed values: EntraOnly or Password.')
@allowed([
  'EntraOnly'
  'Password'
])
param authType string = 'Password'

@description('PostgreSQL admin username.')
param dbUserName string

@secure()
@description('PostgreSQL admin password.')
param dbUserPassword string

@description('List of database names to create.')
param databaseNames array = [ 'testdb' ]

@description('PostgreSQL version.')
param version string = '15'

@description('Storage settings for the server.')
param storage object = {
  storageSizeGB: 32
}

@description('Allow all IPs to access the server (for dev/test only).')
param allowAllIPsFirewall bool = false

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    administratorLogin: dbUserName
    administratorLoginPassword: dbUserPassword
    version: version
    storage: {
      storageSizeGB: storage.storageSizeGB
    }
    authConfig: {
      activeDirectoryAuth: authType == 'EntraOnly' ? 'Enabled' : 'Disabled'
      passwordAuth: authType == 'Password' ? 'Enabled' : 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
}

// Create databases
resource databases 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = [for dbName in databaseNames: {
  parent: server
  name: dbName
  properties: {}
}]

// Allow all IPs (not recommended for production)
resource allowAllIPs 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = if (allowAllIPsFirewall) {
  parent: server
  name: 'AllowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

output POSTGRES_DOMAIN_NAME string = server.properties.fullyQualifiedDomainName
