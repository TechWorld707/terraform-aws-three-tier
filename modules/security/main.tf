locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "security"
    }
  )

  alb_ingress_rules = {
    for pair in setproduct(
      var.alb_ingress_ports,
      var.alb_ingress_cidrs
    ) :
    "${pair[0]}-${pair[1]}" => {
      port = pair[0]
      cidr = pair[1]
    }
  }
}

resource "aws_security_group" "alb" {
  name                   = "${var.name}-alb"
  description            = "Controls inbound traffic to the public ALB"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-alb"
      Tier = "public"
    }
  )
}

resource "aws_security_group" "ecs" {
  name                   = "${var.name}-ecs"
  description            = "Controls traffic to ECS Fargate tasks"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-ecs"
      Tier = "application"
    }
  )
}

resource "aws_security_group" "rds" {
  name                   = "${var.name}-rds"
  description            = "Controls traffic to PostgreSQL"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-rds"
      Tier = "database"
    }
  )
}

resource "aws_security_group" "redis" {
  name                   = "${var.name}-redis"
  description            = "Controls traffic to ElastiCache Redis"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-redis"
      Tier = "cache"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = local.alb_ingress_rules

  security_group_id = aws_security_group.alb.id
  description       = "Public access to ALB port ${each.value.port}"
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB traffic to ECS application"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Application traffic from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.application_port
  to_port                      = var.application_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_postgres" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "ECS traffic to PostgreSQL"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "ECS traffic to Redis"
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS access to AWS APIs through NAT or VPC endpoints"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_udp" {
  security_group_id = aws_security_group.ecs.id
  description       = "UDP DNS resolution inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_dns_tcp" {
  security_group_id = aws_security_group.ecs.id
  description       = "TCP DNS resolution inside the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL access from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.postgres_port
  to_port                      = var.postgres_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis access from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
}