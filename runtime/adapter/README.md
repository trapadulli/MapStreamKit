# Adapter Runtime (Azure Function Ingress)

HTTP ingress function that validates a generic contract envelope and publishes accepted events to Event Hubs.

## Endpoints

- `GET /health`
- `POST /events`

## Accepted contract

`POST /events` expects this JSON shape:

- `contract.version` (string, required)
- `contract.type` (string, required)
- `contract.source` (string, required)
- `payload` (required, any JSON value)
- `metadata` (object, optional)
- `eventId` (string, optional; generated when omitted)

## Example request

```sh
curl -X POST http://localhost:8081/events \
  -H "content-type: application/json" \
  -d '{
    "contract": {
      "version": "1.0",
      "type": "com.mapstreamkit.ingest.item.created",
      "source": "head/puller-a"
    },
    "payload": {
      "itemId": "123",
      "name": "sample"
    },
    "metadata": {
      "tenantId": "acme"
    }
  }'
```

Successful responses return `202 Accepted` and include the `eventId` that was enqueued.
Validation failures return `400` with an `errors` array.

## Function App deploy

```sh
./scripts/release-adapter.sh dev
```
