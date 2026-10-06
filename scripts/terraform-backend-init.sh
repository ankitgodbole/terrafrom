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
  echo "Invalid workspace/container name: $WORKSPACE" >&2
  exit 2
fi

TFVARS="environments/${WORKSPACE}/terraform.tfvars"
if [[ ! -f "$TFVARS" ]]; then
  echo "Missing workspace configuration: $TFVARS" >&2
  exit 1
fi

: "${ARM_CLIENT_ID:?Set ARM_CLIENT_ID for backend OIDC authentication}"
: "${ARM_TENANT_ID:?Set ARM_TENANT_ID for backend OIDC authentication}"
: "${ACTIONS_ID_TOKEN_REQUEST_URL:?GitHub Actions OIDC token URL is unavailable; check id-token: write}"
: "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:?GitHub Actions OIDC token is unavailable; check id-token: write}"

export ARM_USE_OIDC=true
export ARM_USE_AZUREAD=true

echo "Initializing AzureRM backend for container: $WORKSPACE"

terraform init \
  -input=false \
  -reconfigure \
  -backend-config="container_name=${WORKSPACE}" \
  -backend-config="subscription_id=bbdd541c-ac30-44a8-b251-6ceb0006dda0"

terraform workspace select default

echo "Backend initialized; Terraform workspace is: $(terraform workspace show)"
