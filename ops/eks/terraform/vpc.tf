locals {
  networks = {
    # each network block is configured by taking a /16 and dividing by 2
    # this leaves 2 /17's
    # public subnets are taken from the first /17
    # private_subnets are taken from the second half
    stage = {
      cidr = "10.128.0.0/16"
      # public subnets do not need to be as big so we evenly break down a /24
      # 10.128.0.192/26 finishes  the /24 segementation
      # you can see the math for this /16 here https://www.davidc.net/sites/default/subnets/subnets.html?network=10.128.0.0&mask=16&division=23.ff3100
      public_subnets  = ["10.128.0.0/26", "10.128.0.64/26", "10.128.0.128/26"]
      private_subnets = ["10.128.128.0/24", "10.128.129.0/24", "10.128.130.0/24"]
    }
    # to create a new environment with a new network add a segement exactly the same as the one above but bump the /16 octet up by on
  }
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0.0"

  name = "eks-${terraform.workspace}"
  cidr = local.networks[terraform.workspace]["cidr"]

  azs             = [for az in ["a", "b", "c"] : "${local.vars.region}${az}"]
  private_subnets = local.networks[terraform.workspace]["private_subnets"]
  public_subnets  = local.networks[terraform.workspace]["public_subnets"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                          = 1
    "kubernetes.io/cluster/${local.eks.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                 = 1
    "kubernetes.io/cluster/${local.eks.cluster_name}" = "shared"
    # Tags subnets for Karpenter auto-discovery
    (local.karpenter.discovery_key) = local.karpenter.discovery_value
  }
}

module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 3.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids,
        module.vpc.private_route_table_ids,
        module.vpc.public_route_table_ids,
      ])
      tags = { Name = "s3-vpc-endpoint" }
    },
  }
}
