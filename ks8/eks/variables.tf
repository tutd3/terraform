variable aws_account_id {
  description = "AWS Account ID"
  type        = string
}

variable aws_region {
  description = "Your aws region preference"
  type        = string
}

variable cluster_name {
  description = "EKS cluster name"
  type        = string
}

# reference: https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html
variable k8s_version {
  description = "kubernetes version"
  type        = string
}

variable cluster_public_access_cidrs {
  description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0"
  type        = list
  default     = ["0.0.0.0/0"]
}

variable endpoint_private_access {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default is false"
  type        = bool
  default     = false
}

variable endpoint_public_access {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default is true"
  type        = bool
  default     = true
}

variable cluster_tags {
  description = "EKS tags"
  type        = map
  default     = {}
}

# reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster#service_ipv4_cidr
variable "service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. Default is 172.20.0.0/16"
  type        = string
  default     = "172.20.0.0/16"
}

################################################################################
# EKS Node Group
# - reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group
# - map type variable, key is worker node name and inside key is that worker node configuration setting
################################################################################
variable worker_nodes {
  # description = "Map of worker nodes managed by EKS cluster"
  # type        = map
  # default     = {
  #   web = {
  #     # set your node group instances subnet, if you need static public ip then consider using private subnet (NAT)
  #     # NOTE: beware of data transfer cost
  #     subnet_type = "private"
  #     instance_types = ["t3.small"]
  #     capacity_type = "SPOT",
  #     disk_size = 10,
  #     force_update_version = false,
  #     scaling_config = {
  #       desired_size = 2
  #       max_size = 3
  #       min_size = 1
  #     }
  #     kubernetes_labels = {
  #       "service": "web"
  #     }
  #     tags = {
  #       "service": "web"
  #     }
  #   },
  #   loadbalancer = {
  #     subnet_type = "public"
  #     instance_types = ["t3.small"]
  #     capacity_type = "SPOT",
  #     disk_size = 10,
  #     force_update_version = false,
  #     scaling_config = {
  #       desired_size = 2
  #       max_size = 3
  #       min_size = 1
  #     }
  #     kubernetes_labels = {
  #       "service": "loadbalancer"
  #     }
  #     tags = {
  #       "service": "loadbalancer"
  #     }
  #   }
  # }
}

################################################################################
# ECR Variable (Optional)
# - reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
# - map type variable, key is ECR repository name and inside key is that repository configuration setting
################################################################################
variable ecr_projects {
  description = "(Optional) Map of project names to configuration"
  type        = map
  default     = {
    alpha = {
      image_tag_mutability = "MUTABLE",
      scan_on_push         = false
    }
  }
}

################################################################################
# VPC Variable (Optional)
# - fill bellow value if you want to use existing vpc
# - if not provided then this terraform gonna create a new vpc for you (vpc, nat, igw, public and private subnet)
################################################################################
variable new_vpc_cidr_block {
  description = "New VPC creatd for EKS cluster, if variable 'vpc_name' not blank this variable will be ignored"
  type        = string
  default     = "10.0.0.0/16"
}

# if you decide to use existing vpc already created, then please override below variables default value
# also consider reading below docs https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
# in summary, EKS need your subnets to include custom tagging
variable vpc_id {
  description = "AWS VPC id"
  type        = string
  default     = ""
}

variable cluster_subnet_ids {
  description = "(Optional) List of EKS cluster subnet ids"
  type        = list
  default     = []
}

variable cluster_public_subnet_ids {
  description = "(Optional) List of EKS cluster public subnet ids"
  type        = list
  default     = []
}

variable cluster_public_subnet_ids2 {
  description = "(Optional) List of EKS cluster public subnet ids"
  type        = list
  default     = []
}

variable cluster_private_subnet_ids {
  description = "(Optional) List of EKS cluster private subnet ids"
  type        = list
  default     = []
}

variable cluster_private_subnet_ids2 {
  description = "(Optional) List of EKS cluster private subnet ids"
  type        = list
  default     = []
}

variable cluster_private_subnet_ids3 {
  description = "(Optional) List of EKS cluster private subnet ids"
  type        = list
  default     = []
}

variable cluster_public_subnet_ids3 {
  description = "(Optional) List of EKS cluster public subnet ids"
  type        = list
  default     = []
}

variable enable_public_alb {
  type        = bool
  default     = false
}

variable enable_private_alb {
  type        = bool
  default     = false
}

variable enable_demo_alb {
  type        = bool
  default     = false
}


variable create_public_alb {
  type        = bool
  default     = false
}

variable create_private_alb {
  type        = bool
  default     = false
}

variable create_demo_alb {
  type        = bool
  default     = false
}


variable port_tg {
  type        = number
  default     = 30007
}

variable protocol {
  type        = string
  default     = "HTTP"
}

variable target_type {
  type        = string
  default     = "instance"
}

variable path_healthcheck {
  type        = string
  default     = "/healthz"
}

variable port_healhtcheck {
  type        = number
  default     = 30008
}

variable allowed_public_ip {
  type        = list
  default     = ["35.201.197.198/32"]
}

variable allowed_demo_ip {
  type        = list
  default     = ["0.0.0.0/0"]
}
variable public_alb_certificate_arn {
  type        = string
  default     = ""
  description = "ARN Cerficitate for that domain used"
}

variable allowed_private_ip {
  type        = list
  default     = ["10.28.0.0/16","10.29.0.0/16","10.30.0.0/16"]
}

variable private_alb_certificate_arn {
  type        = string
  default     = ""
  description = "ARN Cerficitate for that domain used"
}

variable demo_alb_certificate_arn {
  type        = string
  default     = ""
  description = "ARN Cerficitate for that domain used"
}

variable alb_access_logs_bucket {
  default     = ""
}

variable alb_access_logs_enabled {
  type        = bool
  default     = false
}

variable "aws_auth_additional_labels" {
  description = "additional kubernetes labels applied on aws-auth configmap"
  default     = {}
  type        = map(string)
}

variable "iam_path" {
  description = "if provided, all iam roles will be created on this path."
  type        = string
  default     = "/"
}

variable map_accounts {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type        = list(string)
  default     = []
}


variable map_roles {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable map_users {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = [
    {
      userarn  = "arn:aws:iam::954441176976:user/ricky_hartono"
      username = "ricky_hartono"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::954441176976:user/ardian"
      username = "ardian"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::954441176976:user/wendy.thedy"
      username = "wendy.thedy"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::954441176976:group/DevOps"
      username = "devops"
      groups   = ["system:masters"]
    }
  ]
}

variable manage_aws_auth {
  type = bool
  default = false
}

variable https_default_action_type {
  type = string
  default = "forward"
}

variable ssl_policy_public {
  type = string
  default = "ELBSecurityPolicy-FS-1-2-2019-08"
}

variable ssl_policy_private {
  type = string
  default = "ELBSecurityPolicy-FS-1-2-2019-08"
}

variable ssl_policy_demo {
  type = string
  default = "ELBSecurityPolicy-FS-1-2-2019-08"
}

variable alb_idle_timeout {
  type = number
  default = 300
}

variable "cluster_addons" {
  description = "EKS addons"
  default     = {}
}

variable "cluster_addons_timeouts" {
  type        = map(string)
  default     = {}
}

variable use_custom_launch_template {
  description = "For using launch template on node worker"
  type        = bool
  default     = false
}
variable launch_template_variable {
  description = "launch template variable"
  type        = map
  default     = {}
}