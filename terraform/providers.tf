terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Cambia a tu región preferida
  default_tags {
    tags = {
      Management = "Terraform"
    }
  }
}
