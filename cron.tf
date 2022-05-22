resource "aws_iam_role" "ecs_events" {
  count = contains(["CRON"], var.ecs_settings.run_type) ? 1 : 0
  name  = var.application_config.name
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "events.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  count = contains(["CRON"], var.ecs_settings.run_type) ? 1 : 0

  name = var.application_config.name
  role = aws_iam_role.ecs_events[0].id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : "ecs:RunTask",
          "Resource" : replace(aws_ecs_task_definition.service.arn, "/:\\d+$/", ":*")
        }
      ]
  })
}

module "cron" {
  source              = "./cron/"
  for_each            = { for cron in var.cron.settings : replace(cron.name, ":", "-") => cron }
  application_config  = var.application_config
  cron_settings       = merge(each.value, { execution_script = var.cron.execution_script })
  ecs_settings        = var.ecs_settings
  iam_role_arn        = aws_iam_role.ecs_events[0].arn
  task_definition_arn = aws_ecs_task_definition.service.arn
}