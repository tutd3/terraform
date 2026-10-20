# Pakai SSM Parameter resmi dari AWS, BUKAN data "aws_ami" dengan filter nama
# - filter nama "al2023-ami-*-x86_64" pernah kena bug nyata: wildcard-nya
# kebetulan juga cocok ke varian "al2023-ami-MINIMAL-...-x86_64" (image yang
# sengaja tidak menyertakan SSM Agent, dkk, untuk memperkecil ukuran), dan
# most_recent = true kadang memilih varian minimal itu - instance jadi tidak
# pernah bisa diakses lewat SSM Session Manager meskipun IAM role-nya benar.
# SSM Parameter ini dijamin AWS selalu mengarah ke AMI "default" (bukan
# minimal) yang sudah pre-install SSM Agent.
data "aws_ssm_parameter" "amazon_linux" {
  count = var.ami_id == null ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "Security group untuk instance ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  count = var.enable_ssm ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM role + instance profile khusus supaya SSM Agent di dalam instance bisa
# "daftar" ke AWS Systems Manager - setelah itu bisa diakses lewat Session
# Manager (shell lewat AWS Console/CLI, pakai izin IAM) TANPA perlu SSH key
# atau port 22 terbuka sama sekali. Siapa yang BOLEH mulai sesi SSM diatur
# terpisah lewat IAM policy user/group (lihat modules/iam) - role ini cuma
# mengizinkan instance-nya "dihubungi", bukan menentukan siapa yang boleh
# menghubungi.
resource "aws_iam_role" "ssm" {
  count              = var.enable_ssm ? 1 : 0
  name               = "${var.name}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.name}-ssm-profile"
  role  = aws_iam_role.ssm[0].name
}

resource "aws_instance" "this" {
  ami                    = coalesce(var.ami_id, try(data.aws_ssm_parameter.amazon_linux[0].value, null))
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = var.enable_ssm ? aws_iam_instance_profile.ssm[0].name : var.iam_instance_profile_name

  root_block_device {
    volume_size = var.root_volume_size_gb
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required" # wajibkan IMDSv2, praktik keamanan standar
  }

  tags = merge(var.tags, { Name = var.name })
}
