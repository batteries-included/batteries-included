locals {
  accounts = {
    for acct in data.aws_organizations_organization.orgs.accounts :
    acct.name => acct
  }
  target_account_id = local.accounts["batteriesincl.com"].id

  tags = {
    environment = "main"
    terraform   = "ops/aws/terraform"
  }

  # rearrange SSO roles by name for easier access
  sso_roles = { for i, name in data.aws_iam_roles.sso_roles.names : tolist(split("_", name))[1] => name }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
    "10.0.7.0/24",
    "10.0.8.0/24"
  ]
}

variable "private_subnet_cidr_blocks" {
  description = "Available cidr blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
    "10.0.105.0/24",
    "10.0.106.0/24",
    "10.0.107.0/24",
    "10.0.108.0/24"
  ]
}

# This is the network that wireguard will use
variable "gateway_network_cidr_block" {
  default = "10.250.0.0/24"
}

variable "gateway_ssh_public_key" {
  default = "../keys/gateway_ssh.pub"
}

variable "devserver_ssh_public_key" {
  default = "../keys/devserver_ssh.pub"
}

variable "ebs_volume_type" {
  default = "gp3"
}
variable "gateway_instance_type" {
  default = "t3a.micro"
}

variable "gateway_instance_disk_size" {
  default = "12"
}
