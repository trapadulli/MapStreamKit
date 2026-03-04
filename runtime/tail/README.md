# Tail Runtime (Starter Worker)

Minimal tail processor worker scaffold.

## Local run

```sh
cd runtime/tail
npm start
```

## Behavior

- Logs startup configuration
- Emits periodic worker ticks
- Placeholder for Event Hubs consume/process loop

## Function App deploy

```sh
./scripts/release-tail.sh dev
```
