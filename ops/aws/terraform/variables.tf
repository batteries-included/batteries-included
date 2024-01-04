locals {
  accounts = {
    for acct in data.aws_organizations_organization.orgs.accounts :
    acct.name => acct
  }
  target_account_id = local.accounts["batteriesincl.com"].id

  tags = {
    environment = var.cluster_name
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

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "main"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# This is the network that wireguard will use
variable "gateway_network_cidr_block" {
  default = "10.250.0.0/24"
  type    = string
}

variable "gateway_ssh_public_key" {
  default = "../keys/gateway_ssh.pub"
  type    = string
}

variable "ebs_volume_type" {
  default = "gp3"
  type    = string
}

variable "gateway_instance_type" {
  default = "t3a.micro"
  type    = string
}

variable "gateway_instance_disk_size" {
  default = "12"
  type    = string
}
