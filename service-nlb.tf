resource "aws_ecs_service" "service_net" {
  count = contains(["NLB"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service.id
  desired_count                      = var.desired_count
  scheduling_strategy                = var.scheduling_strategy
  launch_type                        = var.ecs_settings.ecs_launch_type
  deployment_minimum_healthy_percent = var.deployment.minimum_healthy_percent
  deployment_maximum_percent         = var.deployment.maximum_healthy_percent
  propagate_tags                     = "TASK_DEFINITION"

  dynamic "load_balancer" {
    for_each = aws_lb_target_group.network_lb_target
    content {
      target_group_arn = load_balancer.value.arn
      container_port   = load_balancer.value.port
      container_name   = var.application_config.name
    }
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
    Type = "net"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }

}
