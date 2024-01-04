module "vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.4.0"

  name                 = "main"
  cidr                 = var.vpc_cidr_block
  public_subnets       = var.public_subnet_cidr_blocks
  private_subnets      = var.private_subnet_cidr_blocks
  azs                  = data.aws_availability_zones.available.names
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

