locals {
  wireguard = {
    name = "wireguard-${var.cluster_name}"

    # additional roles to attach to the wireguard instance profile
    additional_roles = [
      # allows instance to connect back to SSM for e.g. session manager
      data.aws_iam_policy.ssm_managed_instance_policy.arn,
    ]

    # This is where one would add their wireguard public key to self-provision access.
    # cidrsubnet("100.64.250.0/24", 8, 5) = 100.64.250.5/32
    peers = {
      jdt-desktop = { public_key = "iMQngW+5Wfx2kbAk9qdhiXB46rYUA5c2yDkJRfbHklg=", addr = cidrsubnet(var.gateway_network_cidr_block, 8, 5) }
      # template = { public_key = "<wg_pub_key>", addr = cidrsubnet(var.gateway_network_cidr_block, 8, <last_ip_octet>) }
    }
    key_count = var.generate_gateway_key ? 1 : 0
  }
}

resource "aws_security_group" "wireguard" {
  name   = local.wireguard.name
  vpc_id = module.vpc.vpc_id

  # only add SSH ingress if we're provisioning SSH key
  dynamic "ingress" {
    for_each = var.generate_gateway_key ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.gateway_network_cidr_block]
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

resource "aws_key_pair" "wireguard" {
  count      = local.wireguard.key_count
  key_name   = local.wireguard.name
  public_key = file(var.gateway_ssh_public_key)
}

# trust policy allowing ec2 instances to have a role
data "aws_iam_policy_document" "wireguard_assume_role" {
  statement {
    sid     = "WireguardInstanceAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# the role that will be attached to the wireguard instance
resource "aws_iam_role" "wireguard" {
  name        = local.wireguard.name
  description = "Role for wireguard instance"

  assume_role_policy    = data.aws_iam_policy_document.wireguard_assume_role.json
  force_detach_policies = true
}

# attach each of the managed policies to the role
resource "aws_iam_role_policy_attachment" "wireguard" {
  for_each   = toset(local.wireguard.additional_roles)
  role       = aws_iam_role.wireguard.name
  policy_arn = each.key
}

# create an instance profile that will be attached to the instance
# that has the role and policies above
resource "aws_iam_instance_profile" "wireguard" {
  name = local.wireguard.name
  role = aws_iam_role.wireguard.name
}

data "cloudinit_config" "wireguard" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = yamlencode({
      packages = [
        "apt-transport-https",
        "ca-certificates",
        "net-tools",
        "software-properties-common",
        "ufw",
      ]
      package_update             = true
      package_upgrade            = true
      package_reboot_if_required = true

      write_files = [{ path = "/etc/sysctl.d/99-sysctl.conf", append = true, content = "net.ipv4.ip_forward=1" }, ]
      runcmd      = [["sudo", "sysctl", "-p", ], ]

      snap = {
        commands = [
          ["snap", "install", "amazon-ssm-agent", "--classic"],
          ["snap", "start", "amazon-ssm-agent"],
        ]
      }

      wireguard = {
        interfaces = [
          {
            name        = "wg0"
            config_path = "/etc/wireguard/wg0.conf"
            content = templatefile("./templates/wg0.conf", {
              private_key = file("../keys/gateway")
              address     = var.gateway_network_cidr_block
              listen_port = 51820
              interface   = "ens5"
              peers       = local.wireguard.peers
            })
          },
        ]
      }
    })
  }
}

resource "aws_instance" "wireguard" {
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = module.vpc.public_subnets[0]
  instance_type          = var.gateway_instance_type
  key_name               = try(aws_key_pair.wireguard[0].key_name, null)
  vpc_security_group_ids = [aws_security_group.wireguard.id]
  iam_instance_profile   = aws_iam_instance_profile.wireguard.name

  tags = {
    Name = local.wireguard.name
  }

  user_data_replace_on_change = true
  user_data                   = data.cloudinit_config.wireguard.rendered

  metadata_options {
    http_tokens = "required" # disable IMDSv1
  }

  root_block_device {
    volume_type = var.ebs_volume_type
    volume_size = var.gateway_instance_disk_size
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "wireguard" {
  tags = {
    Name = local.wireguard.name
  }
}

# attach the EIP to the instance separately so that the instance can be
# replaced w/o changing the public IP
resource "aws_eip_association" "wireguard" {
  instance_id   = aws_instance.wireguard.id
  allocation_id = aws_eip.wireguard.id
}

# NOTE(jdt): one can spin up just the gateway with something like:
# terraform apply \
#   -target module.vpc \
#   -target aws_eip_association.wireguard \
#   -target 'aws_iam_role_policy_attachment.wireguard["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]'
