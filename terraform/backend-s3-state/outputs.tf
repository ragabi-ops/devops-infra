output "bucket_name" {
  value       = aws_s3_bucket.state.bucket
  description = "S3 bucket storing Terraform remote state"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.lock.name
  description = "DynamoDB table used for Terraform state locking"
}

output "aws_region" {
  value       = var.aws_region
  description = "Backend region"
}

output "project_name" {
  value       = var.project_name
  description = "Project name used for resource naming"
}
