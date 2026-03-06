# TLDR Deploy (Clean Environment)

This is the shortest complete path to deploy MapStreamKit from scratch.

---

## 1) Prereqs

Install and verify:

```sh
terraform -version
az version
```

For runtime image releases:

```sh
docker version
# optional but recommended
docker buildx version
```

Windows note: run scripts from WSL or Git Bash.

---

## 2) Azure login + subscription

```sh
az login
az account set --subscription "<SUBSCRIPTION_ID>"
az account show --query "{name:name,id:id}" -o table
```

---

## 3) Register required Azure providers (one-time per subscription)

```sh
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.EventHub
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.DocumentDB
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.ManagedIdentity
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.AlertsManagement
```

---

## 4) Create local env config files

Run from repo root:

```sh
cp env/dev/backend.hcl.example env/dev/backend.hcl
cp env/dev/dev.tfvars.example env/dev/dev.tfvars
cp infra-bootstrap/bootstrap.auto.tfvars.example infra-bootstrap/bootstrap.auto.tfvars
```

Edit values:
- `env/dev/backend.hcl`
- `env/dev/dev.tfvars`
- `infra-bootstrap/bootstrap.auto.tfvars`

---

## 5) One-command infra deploy (bootstrap + main infra)

```sh
./scripts/iac.sh dev all
```

If bootstrap already exists, infra-only:

```sh
./scripts/iac.sh dev infra
```

---

## 6) Release runtimes

```sh
scripts/release-dab.sh dev
scripts/release-head.sh dev
```

Notes:
- Scripts auto-resolve ACR.
- Scripts build/push linux/amd64 images.
- If Docker Buildx is unavailable, scripts fall back to `az acr build`.

---

## 7) Smoke test DAB in cloud

```sh
DAB_FQDN=$(az containerapp show -g rg-msk-dev -n ca-msk-dab-dev --query properties.configuration.ingress.fqdn -o tsv)
curl -sS "https://$DAB_FQDN/"
curl -sS -X POST \
  "https://$DAB_FQDN/graphql" \
  -H "Content-Type: application/json" \
  --data '{"query":"query { __typename }"}'
```

Expected:
- Root endpoint returns healthy status payload.
- GraphQL endpoint returns `{"data":{"__typename":"Query"}}`.

---

## 8) Quick verification commands

```sh
az containerapp show -g rg-msk-dev -n ca-msk-dab-dev --query "properties.template.containers[0].image" -o tsv
az containerapp revision list -g rg-msk-dev -n ca-msk-dab-dev -o table
az containerapp logs show -g rg-msk-dev -n ca-msk-dab-dev --tail 100
```

---

## Common gotchas

- If release says ACR cannot be resolved:
  - Run `./scripts/iac.sh dev infra` first.
- If DAB endpoint times out or returns errors:
  - Check DAB logs for config/schema issues.
  - Re-run `scripts/release-dab.sh dev`.
- If first DAB call is slow:
  - Likely cold start; retry once.
