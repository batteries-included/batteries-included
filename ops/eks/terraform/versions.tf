terraform {
  required_version = ">= 1.6.6"

  backend "s3" {
    bucket         = "batteriesincl-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "batteriesincl-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1.14"
    }
  }
}
