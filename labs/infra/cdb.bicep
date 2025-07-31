// Cosmos DB Bicep module for SQL API
@description('Name of the Cosmos DB account.')
param name string

@description('Location for the Cosmos DB account.')
param location string

@description('Tags to apply to the Cosmos DB account.')
param tags object = {}

resource cosmosdb 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: name
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
  // enableFreeTier removed as requested
  }
}

output COSMOSDB_ENDPOINT string = cosmosdb.properties.documentEndpoint
