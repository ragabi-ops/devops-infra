variable "project_name" {
  description = "Short project identifier used to name state resources"
  type        = string
  default     = "checkpoint-cloud"
}

variable "aws_region" {
  description = "AWS region for the backend resources"
  type        = string
  default     = "eu-west-1"
}
