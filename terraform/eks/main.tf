data "aws_caller_identity" "current" {}


# Read VPC + subnets from network stack
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    region = var.state_region
    key    = var.network_state_key
  }
}

# Read github oidc role arn from github-oidc stack
data "terraform_remote_state" "github_oidc" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    region = var.state_region
    key    = var.github_oidc_state_key
  }
}

locals {
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
}

# Use community EKS module with version pin
module "eks" {
  enable_irsa = true
  source      = "terraform-aws-modules/eks/aws"
  version     = "~> 20.8" 

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnet_ids

  endpoint_public_access  = true

  enable_cluster_creator_admin_permissions = false

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = 50
    instance_types = var.node_instance_types
  }

  access_entries = merge(
    # existing GitHub entry above
    data.terraform_remote_state.github_oidc.outputs.github_actions_role_arn == null ? {} : {
      github_ci = {
        principal_arn = data.terraform_remote_state.github_oidc.outputs.github_actions_role_arn
        policy_associations = [{
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster", namespaces = [] }
        }]
      }
    },
    {
      sso_admin = {
        principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/${var.aws_region}/AWSReservedSSO_AdministratorAccess_fe720cc4333d9901"
        policy_associations = [{
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster", namespaces = [] }
        }]
      }
    }
  )

  eks_managed_node_groups = {
    default = {
      name         = "${var.project_name}"
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size
    }
  }

  tags = {
    Project = var.project_name
    Stack   = "eks"
  }
}
