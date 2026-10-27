locals {
  # Pilih map subnet (publik/privat) sesuai var.public, lalu pilih AZ:
  # - var.availability_zone diisi eksplisit (mis. "ap-southeast-3b") -> pakai itu
  # - dikosongkan -> otomatis pakai AZ pertama yang tersedia (urut nama)
  subnet_by_az = var.public ? data.terraform_remote_state.vpc.outputs.public_subnets_by_az : data.terraform_remote_state.vpc.outputs.private_subnets_by_az
  selected_az  = var.availability_zone != "" ? var.availability_zone : sort(keys(local.subnet_by_az))[0]
  subnet_id    = local.subnet_by_az[local.selected_az]
}

module "wetech_devops_prod" {
  source = "../../../../modules/ec2"

  # Naming standar untuk semua instance EC2: wetech-<service>-<environment>
  name                = "wetech-${var.service_name}-prod"
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_id           = local.subnet_id
  instance_type       = var.instance_type
  ami_id              = var.ami_id
  root_volume_size_gb = var.root_volume_size_gb
  key_name            = var.ec2_key_name

  # Akses ke instance ini lewat AWS Systems Manager Session Manager
  # (enable_ssm default true di modul) - tidak perlu SSH/port 22 terbuka
  # sama sekali untuk itu. Siapa yang boleh mulai sesi SSM diatur lewat
  # group IAM (saat ini: admin saja, lihat modules/iam), bukan lewat
  # security group.
  #
  # Rule di bawah ini buka SEMUA port TCP, tapi cuma untuk traffic yang
  # asalnya dari dalam VPC sendiri (cidr_blocks = CIDR VPC, BUKAN
  # 0.0.0.0/0) - jadi tidak terekspos ke internet.
  ingress_rules = [
    {
      description = "All TCP dari dalam VPC saja"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc_cidr]
    }
  ]

  # Security group yang dibuat manual di AWS Console, di-attach ke instance
  # ini selain security group bawaan modul di atas.
  additional_security_group_ids = [
    "sg-08b78dd35ea62cba1",
    "sg-0161da61ad4b601fd",
  ]

  # Instance ini jadi GitHub Actions self-hosted runner - build image lalu
  # push ke ECR. SENGAJA wildcard ke SEMUA repository ECR di akun & region
  # ini (bukan dibatasi 1 repo) - termasuk repository yang ditambah MANUAL
  # (bukan lewat stack envs/production/ecr/*), supaya tidak perlu update
  # Terraform tiap kali ada repository baru. Trade-off: runner ini bisa
  # push/pull ke ECR repo APA PUN di akun ini, bukan cuma yang "miliknya".
  inline_iam_policies = {
    ecr-push-pull-all = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "ECRAuth"
          Effect   = "Allow"
          Action   = "ecr:GetAuthorizationToken"
          Resource = "*"
        },
        {
          Sid    = "ECRPushPullAllRepositories"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer",
          ]
          Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Service     = var.service_name
  }
}
