output "gateway" {
  value = {
    instance_id = aws_instance.wireguard.id
    private_ip  = aws_instance.wireguard.private_ip
    public_ip   = aws_eip.wireguard.public_ip
    private_dns = aws_instance.wireguard.private_dns
    public_dns  = aws_instance.wireguard.public_dns
  }
}

output "subnets" {
  value = {
    public  = local.public_subnets
    private = local.private_subnets
  }
}
