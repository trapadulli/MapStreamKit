#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/iac.sh <environment> <action>

Actions:
  all        Run bootstrap then infra (one-command full workflow).
  preflight  Validate required tools, Azure auth, and config files.
  bootstrap  Initialize and apply infra-bootstrap (first time only).
  infra      Initialize backend, create a plan, and apply it.
  plan       Initialize backend and create a plan file.
  apply      Initialize backend, create a plan, and apply it.
  recreate   Destroy and recreate the environment (with confirmation).
  destroy    Destroy infrastructure only (no confirmation, bootstrap persists).
  delete     Alias for destroy.
  destroy-all Destroy both infrastructure and bootstrap (complete wipe).

Environment file resolution order:
  Backend config:
    1) env/<environment>/backend.hcl

  Terraform vars:
    1) env/<environment>/<environment>.tfvars

Examples:
  ./scripts/iac.sh dev all
  ./scripts/iac.sh dev preflight
  ./scripts/iac.sh dev bootstrap
  ./scripts/iac.sh dev infra
  ./scripts/iac.sh dev plan
  ./scripts/iac.sh dev apply
  ./scripts/iac.sh dev recreate
  ./scripts/iac.sh dev destroy
  ./scripts/iac.sh dev destroy-all
EOF
}

if [[ $# -ne 2 ]]; then
  usage
  exit 1
fi

ENVIRONMENT="$1"
ACTION="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="$REPO_ROOT/infra"
BOOTSTRAP_DIR="$REPO_ROOT/infra-bootstrap"
PLAN_DIR="$INFRA_DIR/.plans"
PLAN_FILE="$PLAN_DIR/${ENVIRONMENT}.tfplan"

ENV_DIR="$REPO_ROOT/env/$ENVIRONMENT"
ENV_BACKEND_FILE="$ENV_DIR/backend.hcl"
ENV_TFVARS_FILE="$ENV_DIR/${ENVIRONMENT}.tfvars"

ENV_BOOTSTRAP_TFVARS_FILE="$ENV_DIR/bootstrap.tfvars"
LEGACY_BOOTSTRAP_TFVARS_FILE="$BOOTSTRAP_DIR/bootstrap.auto.tfvars"

resolve_infra_files() {
  if [[ -f "$ENV_BACKEND_FILE" ]]; then
    BACKEND_FILE="$ENV_BACKEND_FILE"
  else
    echo "Error: backend config not found. Expected:"
    echo "  - $ENV_BACKEND_FILE"
    exit 1
  fi

  if [[ -f "$ENV_TFVARS_FILE" ]]; then
    TFVARS_FILE="$ENV_TFVARS_FILE"
  else
    echo "Error: tfvars not found. Expected:"
    echo "  - $ENV_TFVARS_FILE"
    exit 1
  fi
}

resolve_bootstrap_file() {
  if [[ -f "$ENV_BOOTSTRAP_TFVARS_FILE" ]]; then
    BOOTSTRAP_TFVARS_FILE="$ENV_BOOTSTRAP_TFVARS_FILE"
  elif [[ -f "$LEGACY_BOOTSTRAP_TFVARS_FILE" ]]; then
    BOOTSTRAP_TFVARS_FILE="$LEGACY_BOOTSTRAP_TFVARS_FILE"
  else
    echo "Error: bootstrap tfvars not found. Expected one of:"
    echo "  - $ENV_BOOTSTRAP_TFVARS_FILE"
    echo "  - $LEGACY_BOOTSTRAP_TFVARS_FILE"
    exit 1
  fi
}

run_init() {
  terraform -chdir="$INFRA_DIR" init -reconfigure -backend-config="$BACKEND_FILE"
}

run_bootstrap() {
  terraform -chdir="$BOOTSTRAP_DIR" init
  terraform -chdir="$BOOTSTRAP_DIR" plan -var-file="$BOOTSTRAP_TFVARS_FILE"
  terraform -chdir="$BOOTSTRAP_DIR" apply -var-file="$BOOTSTRAP_TFVARS_FILE" -auto-approve
}

run_plan() {
  mkdir -p "$PLAN_DIR"
  local -a extra_plan_args=()
  if [[ -n "${IAC_TERRAFORM_PLAN_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    extra_plan_args=(${IAC_TERRAFORM_PLAN_ARGS})
  fi

  if (( ${#extra_plan_args[@]} > 0 )); then
    terraform -chdir="$INFRA_DIR" plan -var-file="$TFVARS_FILE" "${extra_plan_args[@]}" -out="$PLAN_FILE"
  else
    terraform -chdir="$INFRA_DIR" plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE"
  fi
  echo "Plan file created: $PLAN_FILE"
}

run_apply() {
  terraform -chdir="$INFRA_DIR" apply "$PLAN_FILE"
}

run_preflight() {
  echo "Running preflight checks..."

  if ! command -v terraform >/dev/null 2>&1; then
    echo "Error: terraform not found in PATH."
    exit 1
  fi

  if ! command -v az >/dev/null 2>&1; then
    echo "Error: Azure CLI (az) not found in PATH."
    exit 1
  fi

  if ! az account show >/dev/null 2>&1; then
    echo "Error: Azure CLI is not authenticated or no subscription is selected."
    echo "Run: az login && az account set --subscription \"<SUBSCRIPTION_ID>\""
    exit 1
  fi

  resolve_bootstrap_file
  resolve_infra_files

  if [[ ! -d "$INFRA_DIR" ]]; then
    echo "Error: infra directory not found at $INFRA_DIR"
    exit 1
  fi

  if [[ ! -d "$BOOTSTRAP_DIR" ]]; then
    echo "Error: infra-bootstrap directory not found at $BOOTSTRAP_DIR"
    exit 1
  fi

  echo "Preflight OK"
  echo "  Azure account: $(az account show --query name -o tsv)"
  echo "  Bootstrap tfvars: $BOOTSTRAP_TFVARS_FILE"
  echo "  Backend config: $BACKEND_FILE"
  echo "  Infra tfvars: $TFVARS_FILE"
}

confirm_recreate() {
  if [[ "${IAC_SKIP_CONFIRM:-false}" == "true" ]]; then
    return 0
  fi

  echo "WARNING: recreate will destroy and re-create environment '$ENVIRONMENT'."
  echo "Type YES to continue:"
  read -r response
  if [[ "$response" != "YES" ]]; then
    echo "Cancelled."
    exit 1
  fi
}

echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"

case "$ACTION" in
  all)
    run_preflight
    run_bootstrap
    run_init
    run_plan
    run_apply
    ;;
  preflight)
    run_preflight
    ;;
  bootstrap)
    resolve_bootstrap_file
    echo "Bootstrap tfvars: $BOOTSTRAP_TFVARS_FILE"
    run_bootstrap
    ;;
  infra)
    resolve_infra_files
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    run_init
    run_plan
    run_apply
    ;;
  plan)
    resolve_infra_files
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    run_init
    run_plan
    ;;
  apply)
    resolve_infra_files
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    run_init
    run_plan
    run_apply
    ;;
  recreate)
    resolve_infra_files
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    confirm_recreate
    run_init
    terraform -chdir="$INFRA_DIR" destroy -var-file="$TFVARS_FILE" -auto-approve
    run_plan
    run_apply
    ;;
  destroy | delete)
    resolve_infra_files
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    run_init
    terraform -chdir="$INFRA_DIR" destroy -var-file="$TFVARS_FILE" -auto-approve
    ;;
  destroy-all)
    resolve_infra_files
    resolve_bootstrap_file
    echo "Backend config: $BACKEND_FILE"
    echo "Tfvars: $TFVARS_FILE"
    echo "Bootstrap tfvars: $BOOTSTRAP_TFVARS_FILE"
    run_init
    terraform -chdir="$INFRA_DIR" destroy -var-file="$TFVARS_FILE" -auto-approve
    terraform -chdir="$BOOTSTRAP_DIR" destroy -var-file="$BOOTSTRAP_TFVARS_FILE" -auto-approve
    ;;
  *)
    echo "Error: unknown action '$ACTION'"
    usage
    exit 1
    ;;
esac
