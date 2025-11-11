variable "aws_region"   { 
  type = string 
  default = "eu-west-1"
}
variable "project_name" { 
  type = string 
  default = "checkpoint-cloud"
}

# GitHub repo coordinates
variable "github_owner" { 
  type = string 
  description = "GitHub org/user, e.g. 'my-org'" 
  default = "ragabi-ops"
}

variable "github_repo"  { 
  type = string
  description = "GitHub repo name, e.g. 'infra'" 
  default = "*"
}

# Allow either branches or environments (or both)
variable "allowed_branches" {
  type        = list(string)
  default     = ["master", "feature/*", "release/*"]
  description = "Branches allowed to assume the role (e.g. ['master','feature/*','release/*'])"
}

variable "allowed_environments" {
  type        = list(string)
  default     = []
  description = "GitHub Environments allowed to assume the role (e.g. ['dev','stg','prod'])"
}

# Thumbprints for token.actions.githubusercontent.com.
# Default includes the commonly used root CA thumbprint; override as needed.
variable "oidc_thumbprints" {
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  description = "Thumbprint list for the GitHub OIDC provider. Verify with AWS docs/security notices."
}

# Optional inline policy for the role (least privilege strongly recommended)
variable "role_inline_policies" {
  type        = map(string)
  default     = {}
  description = "Map of policyName => JSON policy document (jsonencode string) to attach inline"
}

# Optional AWS managed policy ARNs to attach
variable "role_managed_policy_arns" {
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
  description = "List of AWS managed policy ARNs to attach to the role"
}
