module "example_ec2" {
  source = "../../../modules/ec2"

  name      = "${var.name_prefix}-example"
  vpc_id    = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  key_name  = var.ec2_key_name

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
    Environment = "dev"
  }
}
