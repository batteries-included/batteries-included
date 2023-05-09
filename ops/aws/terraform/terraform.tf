terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.56.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "SystemAdministrator-037532365270"
}
