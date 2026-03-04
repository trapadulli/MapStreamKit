const { createServer } = require('node:http');
const { createYoga, createSchema } = require('graphql-yoga');

const port = Number(process.env.PORT || 4000);

const cosmosEndpoint = process.env.COSMOS_ENDPOINT || '';
const cosmosDatabase = process.env.COSMOS_DB || '';
const cosmosContainer = process.env.COSMOS_CONTAINER || '';
const appInsightsConnectionString = process.env.APPINSIGHTS_CONNECTION_STRING || '';

const schema = createSchema({
  typeDefs: /* GraphQL */ `
    type ServiceInfo {
      cosmosConfigured: Boolean!
      appInsightsConfigured: Boolean!
      cosmosEndpoint: String
      cosmosDatabase: String
      cosmosContainer: String
    }

    type Query {
      health: String!
      serviceInfo: ServiceInfo!
    }
  `,
  resolvers: {
    Query: {
      health: () => 'ok',
      serviceInfo: () => ({
        cosmosConfigured: Boolean(cosmosEndpoint && cosmosDatabase && cosmosContainer),
        appInsightsConfigured: Boolean(appInsightsConnectionString),
        cosmosEndpoint: cosmosEndpoint || null,
        cosmosDatabase: cosmosDatabase || null,
        cosmosContainer: cosmosContainer || null,
      }),
    },
  },
});

const yoga = createYoga({
  schema,
  graphqlEndpoint: '/graphql',
});

const server = createServer(yoga);

server.listen(port, () => {
  console.log(`msk-graphql listening on :${port}`);
});
