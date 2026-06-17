terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket       = "tf-state-bucket-646627758157-ap-southeast-2-an"
    key          = "aws-ecs-ghcr-demo/terraform.tfstate"
    region       = var.region
    encrypt      = true
    use_lockfile = true
  }
}
