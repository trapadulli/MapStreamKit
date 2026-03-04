# GraphQL Consumer Runtime

Minimal GraphQL service for the MapStreamKit GraphQL Container App.

## Local run

```sh
cd runtime/graphql
npm install
npm start
```

Defaults:
- Port: `4000`
- Endpoint: `/graphql`

## Environment variables

- `PORT` (default `4000`)
- `COSMOS_ENDPOINT`
- `COSMOS_DB`
- `COSMOS_CONTAINER`
- `APPINSIGHTS_CONNECTION_STRING`

## Example query

```graphql
query {
  health
  serviceInfo {
    cosmosConfigured
    appInsightsConfigured
    cosmosEndpoint
    cosmosDatabase
    cosmosContainer
  }
}
```
