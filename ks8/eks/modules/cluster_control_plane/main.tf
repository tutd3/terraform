################################################################################
# IAM Role for EKS Cluster
# - assign policy 'AmazonEKSClusterPolicy' and 'AmazonEKSServicePolicy'
################################################################################
resource "aws_iam_role" "control_plane" {
  name = "${var.cluster_name}-control-plan-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.control_plane.name
}

resource "aws_iam_role_policy_attachment" "service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.control_plane.name
}

################################################################################
# Cluster control plane
################################################################################
resource "aws_security_group" "cluster_to_worker" {
  name        = "${var.cluster_name}-cluster-to-worker-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster" "main" {
  name            = var.cluster_name
  version         = var.k8s_version
  role_arn        = aws_iam_role.control_plane.arn

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    public_access_cidrs     = var.public_access_cidrs
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = [aws_security_group.cluster_to_worker.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.service,
  ]

  tags = var.cluster_tags
}

################################################################################
# Cluster autoscaler related configuration
################################################################################
data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity.0.oidc.0.issuer

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.main.identity.0.oidc.0.issuer

  depends_on = [
    data.tls_certificate.main
  ]
}

locals {
  identity_oidc_issuer = replace(aws_eks_cluster.main.identity.0.oidc.0.issuer, "https://", "")
}

resource "aws_iam_policy" "autoscaler" {
  name   = "${var.cluster_name}-autoscaler-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}

POLICY
}

resource "aws_iam_role" "autoscaler" {
  name               = "${var.cluster_name}-autoscaler-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.identity_oidc_issuer}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${local.identity_oidc_issuer}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }
  ]
}
POLICY

  depends_on = [
    aws_eks_cluster.main
  ]
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.autoscaler.name

  depends_on = [
    aws_iam_policy.autoscaler,
    aws_iam_role.autoscaler,
  ]
}