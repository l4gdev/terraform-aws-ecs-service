
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.auto_scaling.maximum
  min_capacity       = var.auto_scaling.minimum
  resource_id        = "service/${var.cluster_name}/${var.app_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

module "rules" {
  source       = "./rules"
  for_each     = toset(local.to_set_of_str)
  rule         = each.value
  ecs_target   = aws_appautoscaling_target.ecs_target
  service      = var.service_name
  cluster_name = var.cluster_name
  app_name     = var.app_name
}

locals {
  to_set_of_str = [for rule in var.auto_scaling.rules : jsonencode(rule)]
}
