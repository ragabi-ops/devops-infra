# Network Stack

Creates:
- VPC with DNS
- 2 public subnets, 2 private subnets (minimum across two AZs)
- IGW, optional single NAT GW (default), route tables and associations
- A basic application SG

**Backend** is configured via `backend.hcl` written by `../../scripts/write-backend-config.sh`.
