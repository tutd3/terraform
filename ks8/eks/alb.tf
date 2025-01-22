resource "aws_lb" "public" {
  count = var.create_public_alb ? 1 : 0

  name = format("%s-pub-lb", var.cluster_name)

  internal           = false
  load_balancer_type = "application"

  security_groups = concat(
    aws_security_group.alb_public.*.id
  )

  subnets = local.cluster_public_subnet_ids

  access_logs {
    bucket  = var.alb_access_logs_bucket
    prefix  = format("alb-%s/public", var.cluster_name)
    enabled = var.alb_access_logs_enabled
  }

  idle_timeout = var.alb_idle_timeout
  enable_http2 = true

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_listener" "http" {
  count = var.create_public_alb ? 1 : 0
  load_balancer_arn = aws_lb.public[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    var.cluster_tags
  )
}


resource "aws_lb_listener" "https" {
  count = var.create_public_alb ? 1 : 0

  load_balancer_arn = aws_lb.public[0].arn

  port            = 443
  protocol        = "HTTPS"
  certificate_arn = var.public_alb_certificate_arn
  ssl_policy      = var.ssl_policy_public

  dynamic "default_action" {
    for_each = var.https_default_action_type == "forward" ? [1] : []
    content {
      type             = var.https_default_action_type
      target_group_arn = aws_lb_target_group.public[0].arn
    }
  }

  dynamic "default_action" {
    for_each = var.https_default_action_type == "fixed-response" ? [1] : []
    content {
      type             = var.https_default_action_type
      fixed_response {
        content_type = "text/plain"
        status_code  = "404"
      }
    }
  }

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb" "private" {
  count = var.create_private_alb ? 1 : 0

  name = format("%s-pvt-lb", var.cluster_name)

  internal           = true
  load_balancer_type = "application"

  security_groups = concat(
    aws_security_group.alb_private.*.id
  )

  subnets = local.cluster_private_subnet_ids

  access_logs {
    bucket  = var.alb_access_logs_bucket
    prefix  = format("alb-%s/private", var.cluster_name)
    enabled = var.alb_access_logs_enabled
  }

  idle_timeout = var.alb_idle_timeout
  enable_http2 = true

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_listener" "private_http" {
  count = var.create_private_alb ? 1 : 0
  load_balancer_arn = aws_lb.private[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_listener" "private_https" {
  count = var.create_private_alb ? 1 : 0

  load_balancer_arn = aws_lb.private[0].arn

  port            = 443
  protocol        = "HTTPS"
  certificate_arn = var.private_alb_certificate_arn
  ssl_policy      = var.ssl_policy_private

  dynamic "default_action" {
    for_each = var.https_default_action_type == "forward" ? [1] : []
    content {
      type             = var.https_default_action_type
      target_group_arn = aws_lb_target_group.private[0].arn
    }
  }

  dynamic "default_action" {
    for_each = var.https_default_action_type == "fixed-response" ? [1] : []
    content {
      type             = var.https_default_action_type
      fixed_response {
        content_type = "text/plain"
        status_code  = "404"
      }
    }
  }

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb" "demo" {
  count = var.create_demo_alb ? 1 : 0

  name = format("%s-dem-lb", var.cluster_name)

  internal           = false
  load_balancer_type = "application"

  security_groups = concat(
    aws_security_group.alb_demo.*.id
  )

  subnets = local.cluster_public_subnet_ids

  access_logs {
    bucket  = var.alb_access_logs_bucket
    prefix  = format("alb-%s/demo", var.cluster_name)
    enabled = var.alb_access_logs_enabled
  }

  idle_timeout = var.alb_idle_timeout
  enable_http2 = true

  tags = merge(
    var.cluster_tags
  )
}

resource "aws_lb_listener" "demo_http" {
  count = var.create_demo_alb ? 1 : 0
  load_balancer_arn = aws_lb.demo[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(
    var.cluster_tags
  )
}


resource "aws_lb_listener" "demo_https" {
  count = var.create_demo_alb ? 1 : 0

  load_balancer_arn = aws_lb.demo[0].arn

  port            = 443
  protocol        = "HTTPS"
  certificate_arn = var.demo_alb_certificate_arn
  ssl_policy      = var.ssl_policy_demo

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Page Not Found"
      status_code  = "404"
    }
  }

  tags = merge(
    var.cluster_tags
  )
}
