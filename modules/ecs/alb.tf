#checkov:skip=CKV_AWS_150:ALB deletion protection is disabled to support controlled teardown of temporary learning environments.
#checkov:skip=CKV_AWS_91:ALB access logging is deferred until a dedicated centralized log-archive bucket is implemented.
resource "aws_lb" "application" {
  name                       = substr("${var.name}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-alb"
    }
  )
}

resource "aws_lb_target_group" "application" {
  name        = substr("${var.name}-app", 0, 32)
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-application"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
#checkov:skip=CKV_AWS_2:CloudFront provides public HTTPS; ALB HTTPS will be enabled after a domain and ACM certificate are configured.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = local.common_tags
}