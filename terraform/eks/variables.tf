variable "aws_region" {
  type        = string
  description = "AWS region"
  default = "eu-west-1"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default = "checkpoint-cloud"
}

# Remote state (network)
variable "state_bucket" {
  type        = string
  description = "S3 bucket name containing the network state"
}

variable "state_region" {
  type        = string
  description = "Region of the state bucket"
}

variable "network_state_key" {
  type        = string
  description = "Object key for the network state (e.g., network/terraform.tfstate)"
}

variable "github_oidc_state_key" {
  type        = string
  description = "Object key for the github-oidc state (e.g., github-oidc/terraform.tfstate)"
}

# EKS options
variable "cluster_version" {
  type        = string
  default     = "1.33"
  description = "EKS Kubernetes version"
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.large"]
}

variable "desired_size" {
  type        = number
  default     = 1
}

variable "max_size" {
  type        = number
  default     = 2
}

variable "min_size" {
  type        = number
  default     = 1
}
