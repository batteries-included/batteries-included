variable "aws_access_key" {}
variable "aws_secret_key" {}


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

# This is the network that wireguard will use
variable "gateway_network_cidr_block" {
  default = "10.250.0.0/24"
}

variable "gateway_ssh_public_key" {
  default = "../pub_keys/gateway_ssh.pub"
}

variable "devserver_ssh_public_key" {
  default = "../pub_keys/devserver_ssh.pub"
}

variable "ebs_volume_type" {
  default = "gp3"
}
variable "gateway_instance_type" {
  default = "t3.micro"
}

variable "gateway_instance_disk_size" {
  default = "12"
}

variable "devserver_instance_type" {
  default = "m6i.2xlarge"
}

variable "devserver_instance_disk_size" {
  default = "32"
}