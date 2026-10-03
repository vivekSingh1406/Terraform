terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Uses credentials and region from the AWS profile or the repository's .env.
provider "aws" {
  default_tags {
    tags = {
      Project   = "Terraform-MySQL"
      ManagedBy = "Terraform"
    }
  }
}
