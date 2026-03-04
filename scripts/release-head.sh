#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release-head.sh <environment> [image_tag]

Examples:
  ./scripts/release-head.sh dev
  ./scripts/release-head.sh dev 2026-03-03.1

Behavior:
  1) Builds runtime/head image (local Docker or remote ACR build)
  2) Pushes image to <acr_name>.azurecr.io/msk-head:<tag>
  3) Runs Terraform deploy with TF_VAR_head_container_image set to pushed image

ACR resolution order:
  1) ACR_NAME environment variable
  2) Terraform output acr_name for target environment
  3) ACR in resource group rg-msk-<environment> (if exactly one exists)
  4) Existing Container App image on ca-msk-head-<environment>
  5) Single ACR in current subscription (if exactly one exists)
EOF
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
IMAGE_TAG="${2:-$(date +%Y%m%d-%H%M%S)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HEAD_DIR="$REPO_ROOT/runtime/head"

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) not found in PATH."
  exit 1
fi

if [[ ! -f "$HEAD_DIR/Dockerfile" ]]; then
  echo "Error: Head Dockerfile missing at $HEAD_DIR/Dockerfile"
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: Azure CLI is not authenticated."
  echo "Run: az login && az account set --subscription \"<SUBSCRIPTION_ID>\""
  exit 1
fi

resolve_acr_name_from_terraform() {
  local infra_dir="$REPO_ROOT/infra"
  local env_backend_file="$REPO_ROOT/env/$ENVIRONMENT/backend.hcl"

  if [[ ! -f "$env_backend_file" ]]; then
    return 1
  fi

  terraform -chdir="$infra_dir" init -reconfigure -backend-config="$env_backend_file" >/dev/null 2>&1 || return 1
  terraform -chdir="$infra_dir" output -raw acr_name 2>/dev/null || return 1
}

resolve_acr_name_from_resource_group() {
  local rg="rg-msk-${ENVIRONMENT}"
  local acr_count
  acr_count="$(az acr list --resource-group "$rg" --query "length(@)" -o tsv 2>/dev/null || true)"
  if [[ "$acr_count" == "1" ]]; then
    az acr list --resource-group "$rg" --query "[0].name" -o tsv 2>/dev/null || return 1
    return 0
  fi
  return 1
}

ACR_NAME="${ACR_NAME:-}"
if [[ -z "$ACR_NAME" ]]; then
  ACR_NAME="$(resolve_acr_name_from_terraform || true)"
fi

if [[ -z "$ACR_NAME" ]]; then
  ACR_NAME="$(resolve_acr_name_from_resource_group || true)"
fi

if [[ -z "$ACR_NAME" ]]; then
  APP_IMAGE="$(az containerapp show -g "rg-msk-${ENVIRONMENT}" -n "ca-msk-head-${ENVIRONMENT}" --query "properties.template.containers[0].image" -o tsv 2>/dev/null || true)"
  if [[ "$APP_IMAGE" == *".azurecr.io/"* ]]; then
    ACR_NAME="${APP_IMAGE%%.azurecr.io/*}"
  fi
fi

if [[ -z "$ACR_NAME" ]]; then
  ACR_COUNT="$(az acr list --query "length(@)" -o tsv)"
  if [[ "$ACR_COUNT" == "1" ]]; then
    ACR_NAME="$(az acr list --query "[0].name" -o tsv)"
  fi
fi

if [[ -z "$ACR_NAME" ]]; then
  echo "Error: Unable to resolve ACR name."
  echo "Expected one of:"
  echo "  - ACR_NAME env var"
  echo "  - Terraform output acr_name (after infra apply)"
  echo "  - Exactly one ACR in rg-msk-${ENVIRONMENT}"
  echo "  - Existing image on ca-msk-head-${ENVIRONMENT}"
  echo "Quick fix: ./scripts/iac.sh ${ENVIRONMENT} infra"
  echo "Manual override: ACR_NAME=<your-acr> ./scripts/release-head.sh ${ENVIRONMENT}"
  exit 1
fi

IMAGE_REPO="${ACR_NAME}.azurecr.io/msk-head"
IMAGE_URI="${IMAGE_REPO}:${IMAGE_TAG}"

if command -v docker >/dev/null 2>&1; then
  echo "Logging in to ACR: $ACR_NAME"
  az acr login -n "$ACR_NAME"

  echo "Building image locally with Docker: $IMAGE_URI"
  docker build -t "$IMAGE_URI" "$HEAD_DIR"

  echo "Pushing image: $IMAGE_URI"
  docker push "$IMAGE_URI"
else
  echo "Docker not found. Using remote ACR build for: $IMAGE_URI"
  az acr build \
    --registry "$ACR_NAME" \
    --image "msk-head:${IMAGE_TAG}" \
    "$HEAD_DIR"
fi

echo "Deploying infra with head_container_image=$IMAGE_URI"
(
  cd "$REPO_ROOT"
  EXISTING_PLAN_ARGS="${TF_CLI_ARGS_plan:-}"
  EXTRA_PLAN_ARG="-var=head_container_image=${IMAGE_URI}"
  if [[ -n "$EXISTING_PLAN_ARGS" ]]; then
    TF_CLI_ARGS_plan="$EXISTING_PLAN_ARGS $EXTRA_PLAN_ARG" ./scripts/iac.sh "$ENVIRONMENT" infra
  else
    TF_CLI_ARGS_plan="$EXTRA_PLAN_ARG" ./scripts/iac.sh "$ENVIRONMENT" infra
  fi
)

echo "Release completed."
echo "Container image: $IMAGE_URI"
