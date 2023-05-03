# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Amazon Web Services
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_security_group" "ds_config_sg" {
  name        = "${var.deployment_name}-DataSunrise-Config-SG"
  description = "Enables DataSunrise nodes access to dictionary/audit RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.dictionary_db_port
    to_port         = var.dictionary_db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecssg.id]
  }

  ingress {
    from_port       = var.audit_db_port
    to_port         = var.audit_db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecssg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.deployment_name}-DataSunrise-Config-SG"
  }
  depends_on = [aws_security_group.ecssg]
}

data "aws_subnet" "targetcidr" {
  id = var.ASGLB_subnets[0]
}

resource "aws_security_group" "ecssg" {
  name        = "${var.deployment_name}-DataSunrise-ECS-SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = tolist([var.admin_location_CIDR])
  }

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = tolist([var.admin_location_CIDR])
  }

  ingress {
    from_port   = var.ds_instance_port
    to_port     = var.ds_instance_port
    protocol    = "tcp"
    cidr_blocks = tolist([var.admin_location_CIDR])
  }

  ingress {
    cidr_blocks = tolist([var.admin_location_CIDR])
    from_port   = var.container_proxy_port
    to_port     = var.container_proxy_port
    protocol    = "tcp"
  }

  ingress {
    from_port = 11002
    to_port   = 11002
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.deployment_name}-DataSunrise-ECS-SG"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name                 = "${var.deployment_name}-ds-tg"
  port                 = var.container_port
  protocol             = "HTTPS"
  deregistration_delay = 60
  
  health_check {
    protocol            = "HTTPS"
    path                = "/healthcheck/general"
    healthy_threshold   = var.ds_load_balancer_hc_healthy_threshold
    unhealthy_threshold = var.ds_load_balancer_hc_unhealthy_threshold
    interval            = var.ds_load_balancer_hc_interval
    timeout             = var.ds_load_balancer_hc_timeout
  }

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = "86500"
  }

  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_lb_listener" "ListenerHTTPS" {
  load_balancer_arn = aws_lb.ds_ntwrk_load_balancer.arn
  port              = var.container_port
  protocol          = "HTTPS"
  certificate_arn   = var.certificate

  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    type             = "forward"
  }

  depends_on = [aws_lb.ds_ntwrk_load_balancer]
}

resource "aws_lb" "ds_ntwrk_load_balancer" {
  internal                         = var.elb_scheme
  name                             = "${var.deployment_name}-ntwrk-lb"
  #ENTER-SUBNET-IDS-LIST HERE. YOU CAN SEE AN EXAMPLE HOW TO GET FIRST, SECOND ELEMENT FROM THE LIST DEFINED IN VARIAVLES.TF
  subnets                          = var.ASGLB_subnets
  enable_cross_zone_load_balancing = "true"
  load_balancer_type               = "application"
  ip_address_type                  = "ipv4"
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "/ds-ecs/${var.deployment_name}-logs"

  tags = {
    Environment = var.deployment_name
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.containers_count
  min_capacity       = var.containers_count
  resource_id        = "service/${var.deployment_name}-cluster/${aws_ecs_service.aws-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.role.arn
}

resource "aws_iam_instance_profile" "ds_node_profile" {
  name = "${var.deployment_name}-DataSunrise-Node-Profile"
  role = aws_iam_role.role.name
}