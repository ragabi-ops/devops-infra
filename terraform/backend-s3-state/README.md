# Backend S3 State (Bootstrap)

Creates:
- S3 bucket for remote Terraform state (versioned, encrypted, private)
- DynamoDB table for state locking

> Uses **local** state intentionally. Run `terraform apply` here first, then run `../../scripts/write-backend-config.sh` to generate backend files for other stacks.
