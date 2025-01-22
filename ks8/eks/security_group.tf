resource "aws_security_group" "alb_public" {
  count = var.create_public_alb ? 1 : 0

  name        = format("%s-alb-public-sg", var.cluster_name)
  description = "Security group for alb public."
  vpc_id      = var.vpc_id
  tags = merge(
    var.cluster_tags,
    {
      "Name"                                      = "${var.cluster_name}-alb-public-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_public_ip
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_public_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_private" {
  count = var.create_private_alb ? 1 : 0

  name        = format("%s-alb-private-sg", var.cluster_name)
  description = "Security group for alb private."
  vpc_id      = var.vpc_id
  tags = merge(
    var.cluster_tags,
    {
      "Name"                                      = "${var.cluster_name}-alb-private-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_private_ip
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_private_ip
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_demo" {
  count = var.create_demo_alb ? 1 : 0

  name        = format("%s-alb-demo-sg", var.cluster_name)
  description = "Security group for alb demo."
  vpc_id      = var.vpc_id
  tags = merge(
    var.cluster_tags,
    {
      "Name"                                      = "${var.cluster_name}-alb-demo-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
  )
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_demo_ip
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_demo_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
