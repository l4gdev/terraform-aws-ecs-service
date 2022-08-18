
locals {
  rule =  jsondecode(var.rule)
}


resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = local.rule.name
  policy_type        = "StepScaling"
  resource_id        = var.ecs_target.resource_id
  scalable_dimension = var.ecs_target.scalable_dimension
  service_namespace  = var.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = local.rule.cooldown
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = local.rule.scaling_adjustment
    }
  }
}


# CloudWatch alarm that triggers the autoscaling up policy

resource "aws_cloudwatch_metric_alarm" "alert" {

  alarm_name  = "${var.service}-${local.rule.metric}-${local.rule.name}"
  namespace   = "AWS/ECS"
  metric_name = local.rule.metric

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"

  evaluation_periods = local.rule.evaluation_periods
  period             = local.rule.period
  threshold          = local.rule.threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }

  alarm_actions = [
    aws_appautoscaling_policy.ecs_policy.arn
  ]
}
