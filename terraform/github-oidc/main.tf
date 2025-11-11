# OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.oidc_thumbprints

  tags = {
    Project = var.project_name
    Stack   = "github-oidc"
  }
}

locals {
  repo = "${var.github_owner}/${var.github_repo}"

  branch_subjects = [
    for b in var.allowed_branches :
    "repo:${local.repo}:ref:refs/heads/${b}"
  ]

  env_subjects = [
    for e in var.allowed_environments :
    "repo:${local.repo}:environment:${e}"
  ]

  all_subjects = concat(local.branch_subjects, local.env_subjects)
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Restrict to allowed subjects
    dynamic "condition" {
      for_each = length(local.all_subjects) > 0 ? [1] : []
      content {
        test     = "StringLike"
        variable = "token.actions.githubusercontent.com:sub"
        values   = local.all_subjects
      }
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-gha-oidc"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags = {
    Project = var.project_name
    Stack   = "github-oidc"
  }
}

# Attach managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.role_managed_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.key
}

# Inline policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.role_inline_policies
  name   = each.key
  role   = aws_iam_role.github_actions.id
  policy = each.value
}

output "github_oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.github.arn
  description = "ARN of the GitHub OIDC provider"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "Role ARN to assume from GitHub Actions"
}
