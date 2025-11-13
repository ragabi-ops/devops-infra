terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = ">= 5.0" }
    helm       = { source = "hashicorp/helm", version = ">= 2.12.1, < 3.0.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = ">= 2.25" }
    http       = { source = "hashicorp/http", version = ">= 3.4" }
  }
  backend "s3" {} # configured via -backend-config=backend.hcl
}