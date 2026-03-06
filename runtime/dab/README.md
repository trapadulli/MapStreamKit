# Data API Builder Runtime

Data API Builder (DAB) container for exposing GraphQL/REST read APIs over Cosmos DB.

## Local run

```sh
cd runtime/dab
docker build -t msk-dab:dev .
docker run --rm -p 5000:5000 -e COSMOS_CONNECTION_STRING="<cosmos-conn-string>" msk-dab:dev
```

## Endpoints

- GraphQL: `http://localhost:5000/graphql`
- REST: `http://localhost:5000/api`

## Azure deploy

Use:

```sh
scripts/release-dab.sh dev
```
