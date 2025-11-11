# GitHub OIDC + IAM Role

Creates:
- IAM OIDC provider for `token.actions.githubusercontent.com`
- An IAM Role restricted to your repo + selected branches/environments

## Example
```bash
cd terraform/github-oidc
terraform init -backend-config=backend.hcl
terraform apply -auto-approve   -var='aws_region=eu-west-1'   -var='project_name=myproj'   -var='github_owner=my-org'   -var='github_repo=infra'   -var='allowed_branches=["main","release/*"]'   -var='role_managed_policy_arns=["arn:aws:iam::aws:policy/PowerUserAccess"]'
```
Outputs:
- `github_actions_role_arn` → set this in your repo as **Actions secret** `AWS_ROLE_TO_ASSUME`

> For least privilege, prefer inline policies in `role_inline_policies` instead of broad managed policies.
