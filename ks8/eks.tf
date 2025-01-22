module eks {
    source = "./eks"

    aws_account_id= "207567799667"

    aws_region="ap-southeast-1"
    cluster_name="mobee-stg-sg-alph"
    k8s_version= "1.28"
    cluster_public_access_cidrs=[
    # not used since endpoint_public_access is false just a placeholder to satisfy odd AWS api validation
    "0.0.0.0/0"
    ]
    endpoint_private_access=true
    endpoint_public_access=false
    cluster_tags={
    "project" = "mobee"
    "environment" = "stg"
    }
    cluster_addons = {
      coredns = {
        preserve    = true
	most_recent = true
	addons_version = "v1.10.1-eksbuild.1"
	timeouts = {
          create = "25m"
	  delete = "10m"
        }
      }
      kube-proxy = {
        most_recent = true
        addon_version = "v1.27.1-minimal-eksbuild.1"
      }
      vpc-cni = {
        most_recent = false
        addon_version = "v1.19.0-eksbuild.1"
      }
      aws-ebs-csi-driver = {
        most_recent = true
        addon_version = "v2.10.0-eks-1-27-9"
      }
   }

    worker_nodes={
    "spot" = {
        key_name = "spot"
        subnet_type = "private"
        instance_types = ["t3.medium"]
        capacity_type = "SPOT",
        disk_size = 20,
        volume_type = "gp3",
        force_update_version = false,
        taint = "false",
        taint_key = "spotstaging",
        taint_value = "false",

        scaling_config = {
        desired_size = 1
        max_size = 50
        min_size = 1
        }
        kubernetes_labels = {
        "environment" = "production"
        "node" = "spot"
        "project" = "mobee"
        "type" = "applications"
        }
        tags = {
        "Name" = "spot"
        "environment" = "production"
        "node" = "spot"
        "project" = "mobee"
        "type" = "applications"
        }
    }
    }

    # custom lauch template
    use_custom_launch_template=true
    launch_template_variable={
      "gp3" = {
        volume_size = "20"
        volume_type = "gp3"
      }
    }

    ecr_projects={}

    new_vpc_cidr_block=""
    vpc_id="vpc-0baed1da5ec934eeb"
    cluster_subnet_ids=[
    # private subnets zone A, B, C
    "subnet-0ac94c316e25a91e1",
    "subnet-087db403e409e97b5",
    "subnet-0398244ca61329a99",
    # public subnets zone A, B, C
    "subnet-0b465a0ed6485b303",
    "subnet-05cc261f5c0082499",
    "subnet-0ec371dec5fe01815",
    ]
    cluster_public_subnet_ids=[
    "subnet-0b465a0ed6485b303",
    "subnet-05cc261f5c0082499",
    "subnet-0ec371dec5fe01815",
    ]
    cluster_private_subnet_ids=[
    "subnet-0ac94c316e25a91e1",
    "subnet-087db403e409e97b5",
    "subnet-0398244ca61329a99",
    ]

    # for creating LB & TargetGroup
    enable_public_alb=false
    enable_private_alb=false
    enable_demo_alb=false            #false if you don't need target group for Demo ALB
    port_tg = 30007
    protocol = "HTTPS"
    path_healthcheck = "/ambassador/v0/check_alive"
    port_healhtcheck = 30008

    create_public_alb = false
    #public_alb_certificate_arn = "arn:aws:acm:ap-southeast-3:519206906151:certificate/bb24a1e6-44b7-478c-b1bd-d5b93eebd944"

    create_private_alb = false
    #private_alb_certificate_arn = "arn:aws:acm:ap-southeast-3:519206906151:certificate/bb24a1e6-44b7-478c-b1bd-d5b93eebd944"

    create_demo_alb = false       #false if you don't need Public ALB 
    #demo_alb_certificate_arn = "arn:aws:acm:ap-southeast-3:519206906151:certificate/bb24a1e6-44b7-478c-b1bd-d5b93eebd944"

    # for managing aws-auth when creating EKS Cluster
    manage_aws_auth = false

    # for adding roles to aws-auth
    map_roles = [
        {
        rolearn  = "arn:aws:iam::207567799667:role/aws-role-root"
        username = "terraform"
        groups   = ["eks-stg"]
        },
    ]

    map_users = [
        {
        userarn = "arn:aws:sts::207567799667:assumed-role/Admin_akses/terraform"
        username= "terraform"
        groups = ["eks-stg"]
        },
    ]

    # IP allowed for accessing ALB Private & Public
    allowed_private_ip = ["10.28.0.0/16","10.29.0.0/16","10.30.0.0/16","10.34.0.0/16","10.35.0.0/16","10.50.0.0/16","10.61.0.0/16","10.110.0.0/16","10.79.0.0/16","172.31.0.0/16","10.77.0.0/16"]

    allowed_public_ip = ["0.0.0.0/0"]

    allowed_demo_ip = ["3.1.164.58/32","35.201.197.198/32","35.198.247.80/32","13.214.108.149/32","13.229.16.191/32","34.87.94.106/32","108.136.86.99/32","18.136.72.232/32","52.76.87.138/32","108.136.199.33/32","52.76.116.219/32","13.250.229.40/32"]

}
