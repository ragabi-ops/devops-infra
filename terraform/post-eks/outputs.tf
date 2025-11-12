output "iam_role_arn" {
  description = "IRSA IAM role ARN for the AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller_irsa.arn
}

output "policy_arn" {
  description = "IAM policy ARN attached to the controller role"
  value       = local.policy_arn_to_attach
}

output "service_account" {
  description = "Kubernetes ServiceAccount used by the controller"
  value       = "${var.namespace}/${var.service_account_name}"
}
