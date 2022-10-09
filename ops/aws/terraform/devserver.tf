resource "aws_security_group" "devserver" {
  name   = "devserver"
  vpc_id = module.vpc_main.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.gateway_network_cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.gateway_network_cidr_block, var.vpc_cidr_block]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.gateway_network_cidr_block, var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "devserver" {
  key_name   = "devserver"
  public_key = file(var.devserver_ssh_public_key)
}

resource "aws_instance" "elliott" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = module.vpc_main.public_subnets[1]
  instance_type          = var.devserver_instance_type
  key_name               = aws_key_pair.devserver.key_name
  vpc_security_group_ids = [aws_security_group.devserver.id]

  root_block_device {
    volume_type = var.ebs_volume_type
    volume_size = var.gateway_instance_disk_size
  }


  lifecycle {
    ignore_changes = [ami]
  }
}