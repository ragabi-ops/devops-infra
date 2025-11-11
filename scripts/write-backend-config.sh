#!/usr/bin/env bash
set -euo pipefail

# This script reads outputs from terraform/backend-s3-state and writes:
# - terraform/network/backend.hcl
# - terraform/eks/backend.hcl
# - terraform/eks/remote_state.auto.tfvars (bucket/region/key for reading network state)

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/terraform/backend-s3-state"

if [ ! -d "$BACKEND_DIR" ]; then
  echo "backend-s3-state directory not found"; exit 1
fi

pushd "$BACKEND_DIR" >/dev/null

# Ensure state and outputs exist
if ! terraform output >/dev/null 2>&1; then
  echo "Run 'terraform apply' in terraform/backend-s3-state first."; exit 1
fi

BUCKET_NAME="$(terraform output -raw bucket_name)"
DDB_TABLE="$(terraform output -raw dynamodb_table_name)"
REGION="$(terraform output -raw aws_region)"
PROJECT_NAME="$(terraform output -raw project_name)"

popd >/dev/null

# Backend files for other stacks
NETWORK_DIR="$ROOT_DIR/terraform/network"
EKS_DIR="$ROOT_DIR/terraform/eks"

mkdir -p "$NETWORK_DIR" "$EKS_DIR"

cat > "$NETWORK_DIR/backend.hcl" <<EOF
bucket         = "${BUCKET_NAME}"
key            = "network/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${DDB_TABLE}"
encrypt        = true
EOF

cat > "$EKS_DIR/backend.hcl" <<EOF
bucket         = "${BUCKET_NAME}"
key            = "eks/terraform.tfstate"
region         = "${REGION}"
dynamodb_table = "${DDB_TABLE}"
encrypt        = true
EOF

# EKS remote_state variables so it can read network outputs
cat > "$EKS_DIR/remote_state.auto.tfvars" <<EOF
state_bucket         = "${BUCKET_NAME}"
state_region         = "${REGION}"
network_state_key    = "network/terraform.tfstate"
project_name         = "${PROJECT_NAME}"
EOF

echo "Wrote:"
echo " - terraform/network/backend.hcl"
echo " - terraform/eks/backend.hcl"
echo " - terraform/eks/remote_state.auto.tfvars"
