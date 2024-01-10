locals {
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  k8s_exec = [{
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = [
      "eks",
      "get-token",
      "--cluster-name", module.eks.cluster_name,
    ]
  }]
}

terraform {
  required_version = ">= 1.6.6"

  backend "s3" {
    bucket         = "batteriesincl-terraform-state"
    key            = "aws/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "batteriesincl-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.3"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

# provider "aws" {
#   region  = var.aws_region
#   profile = "SystemAdministrator-037532365270"
# }

provider "aws" {
  region = "us-east-1"
  alias  = "mgmt"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate

  dynamic "exec" {
    for_each = local.k8s_exec
    content {
      api_version = exec.value.api_version
      command     = exec.value.command
      args        = exec.value.args
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca_certificate

    dynamic "exec" {
      for_each = local.k8s_exec
      content {
        api_version = exec.value.api_version
        command     = exec.value.command
        args        = exec.value.args
      }
    }
  }

  registry {
    url      = "oci://public.ecr.aws"
    username = data.aws_ecrpublic_authorization_token.token.user_name
    password = data.aws_ecrpublic_authorization_token.token.password
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca_certificate
  apply_retry_count      = 5
  load_config_file       = false

  dynamic "exec" {
    for_each = local.k8s_exec
    content {
      api_version = exec.value.api_version
      command     = exec.value.command
      args        = exec.value.args
    }
  }
}

provider "random" {}
