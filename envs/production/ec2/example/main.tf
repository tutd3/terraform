locals {
  # Pilih map subnet (publik/privat) sesuai var.public, lalu pilih AZ:
  # - var.availability_zone diisi eksplisit (mis. "ap-southeast-3b") -> pakai itu
  # - dikosongkan -> otomatis pakai AZ pertama yang tersedia (urut nama)
  subnet_by_az = var.public ? data.terraform_remote_state.vpc.outputs.public_subnets_by_az : data.terraform_remote_state.vpc.outputs.private_subnets_by_az
  selected_az  = var.availability_zone != "" ? var.availability_zone : sort(keys(local.subnet_by_az))[0]
  subnet_id    = local.subnet_by_az[local.selected_az]
}

module "example_ec2" {
  source = "../../../../modules/ec2"

  name      = "${var.name_prefix}-example"
  vpc_id    = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id = local.subnet_id
  key_name  = var.ec2_key_name

  # SSH cuma masuk akal kalau instance public (punya IP publik). Untuk
  # instance private, port ini tetap "terbuka" di security group tapi tidak
  # reachable dari internet - cuma dari dalam VPC.
  ingress_rules = [
    {
      description = "SSH dari mana saja (ganti ke IP kamu saja untuk produksi)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "example"
  }
}
