resource "aws_ecs_service" "service_web" {
  count = contains(["WEB"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service.id
  desired_count                      = var.deployment.first_deployment_desired_count
  scheduling_strategy                = var.scheduling_strategy
  launch_type                        = var.ecs_settings.ecs_launch_type
  deployment_minimum_healthy_percent = var.deployment.minimum_healthy_percent
  deployment_maximum_percent         = var.deployment.maximum_healthy_percent
  propagate_tags                     = "TASK_DEFINITION"

  load_balancer {
    target_group_arn = aws_lb_target_group.app[0].arn
    container_name   = var.web_server.enabled ? var.web_server.name : var.application_config.name
    container_port   = var.web_server.enabled ? var.web_server.container_port : var.application_config.port
  }

  dynamic "network_configuration" {
    for_each = aws_ecs_task_definition.service.network_mode != "bridge" || var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []
    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = false
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  tags = merge(local.tags, {
    Type = "web"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}
