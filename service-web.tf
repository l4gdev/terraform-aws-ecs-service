resource "aws_ecs_service" "service_web" {
  count = contains(["WEB"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service.id
  desired_count                      = var.desired_count
  scheduling_strategy                = var.scheduling_strategy
  launch_type                        = var.ecs_settings.ecs_launch_type
  deployment_minimum_healthy_percent = var.desired_count == 1 ? 0 : 50
  deployment_maximum_percent         = 150
  propagate_tags                     = "TASK_DEFINITION"

  load_balancer {
    target_group_arn = aws_lb_target_group.app[0].arn
    container_name   = var.ecs_settings.lang == "PHP" ? "nginx" : var.application_config.name
    container_port   = var.ecs_settings.lang == "PHP" ? 80 : var.application_config.port
  }
    dynamic "network_configuration" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []
    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = false
    }
  }

  tags = merge(local.tags, {
    Type = "web"
  })
  lifecycle {
    ignore_changes = [desired_count]
  }

}
