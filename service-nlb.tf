
resource "aws_ecs_service" "service_net" {
  count = contains(["NLB"], var.ecs_settings.run_type) ? 1 : 0

  name                               = var.application_config.name
  cluster                            = var.ecs_settings.ecs_cluster_name
  task_definition                    = aws_ecs_task_definition.service[0].id
  desired_count                      = var.deployment.first_deployment_desired_count
  scheduling_strategy                = var.scheduling_strategy
  launch_type                        = var.capacity_provider_strategy == [] ? var.ecs_settings.ecs_launch_type : null
  deployment_minimum_healthy_percent = var.deployment.minimum_healthy_percent
  deployment_maximum_percent         = var.deployment.maximum_healthy_percent
  propagate_tags                     = "TASK_DEFINITION"

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "load_balancer" {
    for_each = aws_lb_target_group.network_lb_target
    content {
      target_group_arn = load_balancer.value.arn
      container_port   = load_balancer.value.port
      container_name   = var.application_config.name
    }
  }
  dynamic "network_configuration" {
    for_each = aws_ecs_task_definition.service[0].network_mode != "bridge" || var.ecs_settings.ecs_launch_type == "FARGATE" ? [
      1
    ] : []
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
    Type = "net"
  })

  lifecycle {
    ignore_changes = [desired_count]
  }

}
