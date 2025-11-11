variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "project_name" {
  type        = string
  description = "Project name for tagging/names"
  default     = "checkpoint-cloud"
}

variable "azs" {
  description = "At least two AZs, e.g., [\"eu-west-1a\", \"eu-west-1b\"]"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of two public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of two private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway (true) or one per AZ (false)"
  type        = bool
  default     = true
}
