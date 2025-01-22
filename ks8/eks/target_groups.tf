resource "aws_lb_target_group" "public" {
  count = var.enable_public_alb ? 1 : 0
  name = format("tg-%s-pub", var.cluster_name)

  vpc_id           = var.vpc_id
  port             = var.port_tg
  protocol         = var.protocol
  protocol_version = "HTTP1"
  target_type      = var.target_type

  slow_start                    = 60
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled           = true
    healthy_threshold = 3
    path              = var.path_healthcheck
    port              = var.port_healhtcheck
    interval          = 10
    timeout           = 5
  }

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_target_group" "private" {
  count = var.enable_private_alb ? 1 : 0
  name = format("tg-%s-pvt", var.cluster_name)

  vpc_id           = var.vpc_id
  port             = var.port_tg
  protocol         = var.protocol
  protocol_version = "HTTP1"
  target_type      = var.target_type

  slow_start                    = 60
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled           = true
    healthy_threshold = 3
    path              = var.path_healthcheck
    port              = var.port_healhtcheck
    interval          = 10
    timeout           = 5
  }

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_target_group" "demo" {
  count = var.enable_demo_alb ? 1 : 0
  name = format("tg-%s-dem", var.cluster_name)

  vpc_id           = var.vpc_id
  port             = var.port_tg
  protocol         = var.protocol
  protocol_version = "HTTP1"
  target_type      = var.target_type

  slow_start                    = 60
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled           = true
    healthy_threshold = 3
    path              = var.path_healthcheck
    port              = var.port_healhtcheck
    interval          = 10
    timeout           = 5
  }

  tags = merge(
    var.cluster_tags
  )
}


# target group attachment
resource "aws_autoscaling_attachment" "alb_public" {
  count = var.enable_public_alb ? length(var.worker_nodes) : 0
  autoscaling_group_name = module.cluster_worker_nodes.autoscaling_group_name[count.index]
  #alb_target_group_arn   
  lb_target_group_arn = element(aws_lb_target_group.public.*.arn, 0)
}

resource "aws_autoscaling_attachment" "alb_private" {
  count = var.enable_private_alb ? length(var.worker_nodes) : 0
  autoscaling_group_name = module.cluster_worker_nodes.autoscaling_group_name[count.index]
  #alb_target_group_arn   
  lb_target_group_arn = element(aws_lb_target_group.private.*.arn, 0)
}

resource "aws_autoscaling_attachment" "alb_demo" {
  count = var.enable_demo_alb ? length(var.worker_nodes) : 0
  autoscaling_group_name = module.cluster_worker_nodes.autoscaling_group_name[count.index]
  #alb_target_group_arn   
  lb_target_group_arn = element(aws_lb_target_group.demo.*.arn, 0)
}
