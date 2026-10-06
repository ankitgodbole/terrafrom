#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")"
cd "$TERRAFORM_DIR"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <workspace>" >&2
  exit 2
fi

WORKSPACE="$1"
if [[ ! "$WORKSPACE" =~ ^[a-z0-9-]+$ ]]; then
  echo "Invalid workspace: $WORKSPACE" >&2
  exit 2
fi

PLAN_FILE="${WORKSPACE}.tfplan"

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "Missing plan file: $PLAN_FILE" >&2
  exit 1
fi

: "${TF_VAR_client_id:?Set TF_VAR_client_id in the workflow environment}"
: "${TF_VAR_client_secret:?Set TF_VAR_client_secret in the workflow environment}"
: "${TF_VAR_tenant_id:?Set TF_VAR_tenant_id in the workflow environment}"
: "${TF_VAR_subscription_id:?Set TF_VAR_subscription_id in the workflow environment}"

if [[ "$WORKSPACE" == spokes-* ]]; then
  : "${TF_VAR_qg_shared_client_id:?Set QG_SHARED_CLIENT_ID for spokes deployments}"
  : "${TF_VAR_qg_shared_client_secret:?Set QG_SHARED_CLIENT_SECRET for spokes deployments}"
fi

CURRENT_WORKSPACE="$(terraform workspace show)"
if [[ "$CURRENT_WORKSPACE" != "default" ]]; then
  echo "Expected Terraform's default workspace, found '$CURRENT_WORKSPACE'." >&2
  echo "Initialize the selected container with scripts/terraform-backend-init.sh first." >&2
  exit 1
fi

echo "Applying plan: $PLAN_FILE for workspace: $WORKSPACE"
terraform apply \
  -input=false \
  "$PLAN_FILE"

echo "Apply complete for $WORKSPACE"
