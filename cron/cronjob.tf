locals {
  cron_execution_binary = {
    NODE = "node"
  }
}

resource "aws_cloudwatch_event_rule" "rule" {
  name                = "${var.application_config.name}-${replace(var.crone_settings.name, ":", "-")}"
  schedule_expression = var.crone_settings.schedule_expression
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = var.ecs_settings.ecs_cluster_name
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "${var.application_config.name}-${replace(var.crone_settings.name, ":", "-")}"
  arn       = data.aws_ecs_cluster.cluster.arn
  rule      = aws_cloudwatch_event_rule.rule.name
  role_arn  = var.iam_role_arn

  ecs_target {
    task_count          = var.crone_settings.desired_count
    task_definition_arn = var.task_definition_arn
  }

  input = jsonencode(
    {
      "containerOverrides" : [
        {
          "command" : concat([local.cron_execution_binary[var.ecs_settings.lang], var.crone_settings.execution_script], split(" ", var.crone_settings.args))
          "name" : var.application_config.name
        }
      ]
    }
  )
}