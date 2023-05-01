resource "aws_lb_target_group" "app" {
  count                = contains(["WEB"], var.ecs_settings.run_type) ? 1 : 0
  name                 = "${var.application_config.environment}-${var.application_config.name}"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = var.alb_deregistration_delay
  slow_start           = var.alb_slow_start
  dynamic "health_check" {
    for_each = var.health_checks
    content {
      enabled             = health_check.value["enabled"]
      healthy_threshold   = health_check.value["healthy_threshold"]
      interval            = health_check.value["interval"]
      matcher             = health_check.value["matcher"]
      path                = health_check.value["path"]
      timeout             = health_check.value["timeout"]
      unhealthy_threshold = health_check.value["unhealthy_threshold"]
    }
  }
  tags = local.tags
}

resource "aws_lb_target_group" "app_test" {
  count                = contains(["WEB"], var.ecs_settings.run_type) && var.enable_code_build ? 1 : 0
  name                 = "${var.application_config.environment}-${var.application_config.name}-test"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = var.alb_deregistration_delay
  slow_start           = var.alb_slow_start
  dynamic "health_check" {
    for_each = var.health_checks
    content {
      enabled             = health_check.value["enabled"]
      healthy_threshold   = health_check.value["healthy_threshold"]
      interval            = health_check.value["interval"]
      matcher             = health_check.value["matcher"]
      path                = health_check.value["path"]
      timeout             = health_check.value["timeout"]
      unhealthy_threshold = health_check.value["unhealthy_threshold"]
    }
  }
  tags = local.tags
}
