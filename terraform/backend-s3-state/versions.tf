terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
  }
  backend "s3" {
    bucket = "checkpoint-cloud-tf-state"
    key    = "backend-s3-state/backend-s3-state.tfstate"
    region = "eu-west-1"
  }
}
