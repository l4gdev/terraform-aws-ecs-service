resource "aws_ecs_service" "service_worker" {
  count = contains(["WORKER"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service.id
  desired_count                      = var.desired_count
  launch_type                        = var.ecs_settings.ecs_launch_type
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100
  scheduling_strategy                = var.scheduling_strategy

  dynamic "network_configuration" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []
    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = false
    }
  }


  lifecycle {
    ignore_changes = [desired_count]
  }
}
