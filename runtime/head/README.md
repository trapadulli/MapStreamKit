# Head Puller Runtime (Hello)

Minimal hello-world service for the Head Puller Container App.

## Local run

```sh
cd runtime/head
npm start
```

## Endpoints

- `GET /health` -> `{ "status": "ok" }`
- `GET /` -> service hello payload

## Docker

```sh
docker build -t msk-head:dev runtime/head
docker run --rm -p 8080:8080 msk-head:dev
```
