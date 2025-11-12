variable "cluster_name" {
  description = "Existing EKS cluster name"
  type        = string
  default     = "checkpoint-cloud-eks"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "namespace" {
  description = "Namespace to install the controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "K8s ServiceAccount name for the controller"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "helm_chart_version" {
  description = "aws-load-balancer-controller chart version (from eks repo)"
  type        = string
  default     = "1.8.1"
}

variable "create_policy" {
  description = "Create a dedicated IAM policy from upstream JSON"
  type        = bool
  default     = true
}

variable "policy_name" {
  description = "Name for the IAM policy (when create_policy = true)"
  type        = string
  default     = "AWSLoadBalancerControllerIAMPolicy"
}

variable "policy_arn_override" {
  description = "If you already created the IAM policy, provide its ARN and set create_policy=false"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to created AWS resources"
  type        = map(string)
  default     = {}
}
