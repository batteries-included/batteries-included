module "vpc_main" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "main"
  cidr                 = var.vpc_cidr_block
  public_subnets       = var.public_subnet_cidr_blocks
  azs                  = data.aws_availability_zones.available.names
  enable_dns_hostnames = true
}