# Terraform Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.51.1"
    }
  }
}

# Provider Block
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}