resource "aws_lb_listener_rule" "web-app" {
  count        = contains(["WEB"], var.ecs_settings.run_type) ? 1 : 0
  listener_arn = var.alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  dynamic "condition" {
    for_each = var.aws_alb_listener_rule_conditions

    content {
      dynamic "host_header" {
        for_each = condition.value["type"] == "host_header" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value["type"] == "path_pattern" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "source_ip" {
        for_each = condition.value["type"] == "source_ip" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
    }
  }
  tags = local.tags
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.app
    ]
  }
}

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
