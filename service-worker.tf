resource "aws_ecs_service" "service_worker" {
  count = contains(["WORKER"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service.id
  desired_count                      = var.deployment.first_deployment_desired_count
  launch_type                        = var.ecs_settings.ecs_launch_type
  deployment_minimum_healthy_percent = var.deployment.minimum_healthy_percent
  deployment_maximum_percent         = var.deployment.maximum_healthy_percent
  scheduling_strategy                = var.scheduling_strategy
  propagate_tags                     = "TASK_DEFINITION"

  dynamic "network_configuration" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []
    content {
      subnets          = var.subnets
      security_groups  = var.security_groups
      assign_public_ip = false
    }
  }

  tags = merge(local.tags, {
    Command = try(var.worker_configuration.args,"default")
    Type    = "worker"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }
}
