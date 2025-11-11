# EKS Stack

Creates an EKS cluster using `terraform-aws-modules/eks` pinned to a specific version.
Reads VPC ID and private subnets from the *network* stack's remote state via `terraform_remote_state`.

**Backend** is configured via `backend.hcl` written by `../../scripts/write-backend-config.sh`.
The same script creates `remote_state.auto.tfvars` with the bucket/region/key to read the network state.

Then apply:
```bash
terraform apply -auto-approve
```
