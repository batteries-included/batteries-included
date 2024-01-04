data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_organizations_organization" "orgs" {
  provider = aws.mgmt
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.mgmt
}

# the role names are like AWSReservedSSO_${ROLE}_${random_stuff}
data "aws_iam_roles" "sso_roles" {
  name_regex  = "AWSReservedSSO_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_subnets" "disallowed_eks_subnets" {
  filter {
    name = "availability-zone-id"
    # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-subnets
    values = ["use1-az3", "usw1-az2", "cac1-az3"]
  }
}
