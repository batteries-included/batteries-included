locals {
  public_subnets  = [for i, _ in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr_block, 8, i + 1)]
  private_subnets = [for i, _ in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr_block, 8, i + 101)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5.0"

  name                 = var.cluster_name
  cidr                 = var.vpc_cidr_block
  public_subnets       = local.public_subnets
  private_subnets      = local.private_subnets
  azs                  = data.aws_availability_zones.available.names
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    # Tags subnets for Karpenter auto-discovery
    (local.karpenter.discovery_key) = local.karpenter.discovery_value
  }
}
