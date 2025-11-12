# -------- IRSA generic role creation for controllers/addons --------
# Provide a map of roles you want to create. Each entry creates:
# - aws_iam_role with an OIDC trust policy bound to the cluster's issuer
# - Optional aws_iam_role_policy_attachment for AWS-managed policies
# - Optional aws_iam_role_policy inline policies

variable "irsa_roles" {
  description = <<EOT
Map of IRSA role definitions keyed by a short name, e.g.:
irsa_roles = {
  "external-dns" = {
    namespace        = "kube-system"
    service_account  = "external-dns"
    policy_arns      = ["arn:aws:iam::aws:policy/AmazonRoute53FullAccess"]
    inline_policies  = {
      "extra" = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"]
          Resource = "*"
        }]
      })
    }
  }
}
EOT
  type = map(object({
    namespace        = string
    service_account  = string
    policy_arns      = optional(list(string), [])
    inline_policies  = optional(map(string), {})
  }))
  default = {}
}

# Try to use the EKS module's OIDC provider ARN (available in v20+). Fallback to null.
locals {
  oidc_provider_arn = try(module.eks.oidc_provider_arn, null)
  oidc_issuer_url   = try(module.eks.cluster_oidc_issuer_url, null)
}

# Safety check to help users if IRSA output is missing
locals {
  irsa_enabled = local.oidc_provider_arn != null && local.oidc_issuer_url != null
}

# Create IAM roles for each requested IRSA binding
resource "aws_iam_role" "irsa" {
  for_each = var.irsa_roles

  name = "${var.project_name}-${each.key}-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # aud must be sts.amazonaws.com
          "${replace(local.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          # sub binds to a single service account in a namespace
          "${replace(local.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
        }
      }
    }]
  })

  tags = {
    Project   = var.project_name
    Stack     = "eks"
    Component = "irsa"
    Binding   = each.key
  }
}

# Attach AWS-managed policies if provided
resource "aws_iam_role_policy_attachment" "irsa_managed" {
  for_each = {
    for k, v in var.irsa_roles :
    k => v if length(try(v.policy_arns, [])) > 0
  }

  role       = aws_iam_role.irsa[each.key].name
  policy_arn = element(each.value.policy_arns, 0)
}

# If multiple policies are provided, attach all
resource "aws_iam_role_policy_attachment" "irsa_managed_extra" {
  for_each = {
    for pair in flatten([
      for k, v in var.irsa_roles : [
        for idx, arn in tolist(try(v.policy_arns, [])) : {
          key = "${k}-${idx}"
          k   = k
          arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.irsa[each.value.k].name
  policy_arn = each.value.arn
}

# Inline policies
resource "aws_iam_role_policy" "irsa_inline" {
  for_each = {
    for pair in flatten([
      for k, v in var.irsa_roles : [
        for pname, pjson in try(v.inline_policies, {}) : {
          key   = "${k}-${pname}"
          k     = k
          pname = pname
          pjson = pjson
        }
      ]
    ]) : pair.key => pair
  }

  name   = each.value.pname
  role   = aws_iam_role.irsa[each.value.k].id
  policy = each.value.pjson
}

output "irsa_role_arns" {
  description = "Map of created IRSA role ARNs by key"
  value       = { for k, r in aws_iam_role.irsa : k => r.arn }
}
