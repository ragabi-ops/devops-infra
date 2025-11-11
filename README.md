# Terraform AWS Project CheckPoints (S3 Remote Backend, Network, EKS)

This repo contains three stacks:

```
terraform/
  backend-s3-state/   -> bootstrap the S3 state bucket + DynamoDB lock table (remote state in S3)
  network/            -> VPC, subnets, NAT/IGW, basic SGs (remote state in S3)
  eks/                -> EKS cluster using terraform-aws-modules/eks (remote state in S3)
scripts/
  write-backend-config.sh -> Generates backend.hcl files + tfvars from backend outputs
```

## Quick start

1) **Bootstrap the remote backend (remote state in S3):**
```bash
cd terraform/backend-s3-state
terraform init
terraform apply -auto-approve
```

2) **Generate backend configs for other stacks from outputs:**
```bash
# from repo root
./scripts/write-backend-config.sh
```

3) **Provision the network stack (remote state):**
```bash
cd terraform/network
# Uses backend.hcl written by the script above
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

4) **Provision the EKS stack (remote state, consumes network remote state):**
```bash
cd ../eks
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

### Notes
- **Version locking** is enabled via `required_version` and pinned provider versions in each stack.
- The **backend configuration** is intentionally empty in code and supplied at init time with `-backend-config=backend.hcl`. The `write-backend-config.sh` script writes that file using the outputs of the backend bootstrap.
- The EKS stack uses the **`terraform_remote_state`** data source to read the VPC and subnets from the *network* stack's state. The same script writes the correct bucket/region/key into variables automatically.
