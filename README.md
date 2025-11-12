Here’s an updated `README.md` that includes the **GitHub OIDC** stack (to be run *before* EKS) and the **post-EKS** stack (to be run *after* EKS):

---

# Terraform AWS Project CheckPoints (S3 Remote Backend, Network, GitHub OIDC, EKS, Post-EKS)

This repository contains five Terraform stacks deployed in sequence:

```
terraform/
  backend-s3-state/   -> bootstrap the S3 state bucket + DynamoDB lock table (remote state in S3)
  network/            -> VPC, subnets, NAT/IGW, basic SGs (remote state in S3)
  github-oidc/        -> creates AWS IAM OIDC provider + IAM role for GitHub Actions (used by CI/CD)
  eks/                -> EKS cluster using terraform-aws-modules/eks (remote state in S3)
  post-eks/           -> post-cluster setup (IRSA roles, ALB controller Helm release, etc.)
scripts/
  write-backend-config.sh -> generates backend.hcl files + tfvars from backend outputs
```

---

## ⚙️ Deployment Order

### 1️⃣ **Bootstrap the remote backend (S3 + DynamoDB)**

```bash
cd terraform/backend-s3-state
terraform init
terraform apply -auto-approve
```

---

### 2️⃣ **Generate backend configs for other stacks**

```bash
# from repo root
./scripts/write-backend-config.sh
```

This writes `backend.hcl` files under each module using outputs from the backend stack.

---

### 3️⃣ **Deploy the network stack**

```bash
cd terraform/network
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

Creates VPC, subnets, routing, and base security groups.

---

### 4️⃣ **Deploy the GitHub OIDC provider + IAM role (before EKS)**

```bash
cd ../github-oidc
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

This stack:

* Creates the AWS OIDC provider for GitHub Actions (`https://token.actions.githubusercontent.com`).
* Creates the IAM role your GitHub workflows will assume via OIDC.
* Outputs:

  * `github_oidc_provider_arn`
  * `github_actions_role_arn` (used by the EKS access entries).

> **Important:** Run this stack **before the EKS stack**, since the EKS access entries reference the GitHub Actions role ARN.

---

### 5️⃣ **Deploy the EKS cluster**

```bash
cd ../eks
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

This stack:

* Creates the EKS control plane and managed node group(s).
* Reads VPC/subnet info from the network state.
* Grants EKS access entries for:

  * Your GitHub Actions OIDC role (for CI/CD automation)
  * Your AWS SSO Administrator role
* Enables IRSA for controllers and workloads.

---

### 6️⃣ **Deploy post-EKS components (after cluster is up)**

```bash
cd ../post-eks
terraform init -backend-config=backend.hcl
terraform apply -auto-approve
```

This stack configures cluster add-ons such as:

* The AWS Load Balancer Controller (via Helm + IRSA)
* Service accounts and additional controllers
* Any post-cluster setup that depends on a running EKS API

---

## 🧩 Notes

* **Version locking:** Each stack pins `terraform` and provider versions via `required_version` and `required_providers`.
* **Remote state wiring:** Every non-backend stack uses `terraform_remote_state` to read outputs (e.g., VPC IDs, role ARNs).
* **Backend config injection:** All `backend.hcl` files are written automatically by the script after bootstrapping the S3 state.
* **CI/CD:** GitHub Actions workflows use OIDC to authenticate with AWS and deploy these stacks safely without static credentials.


