#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "task_log_group" {
  count             = var.cloudwatch_logs.enabled ? 1 : 0
  name              = "/ecs/${lower(var.ecs_settings.run_type)}/${var.application_config.environment}-${var.application_config.name}"
  retention_in_days = var.cloudwatch_logs.retention_in_days
  tags              = local.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "task_log_group_webserver" {
  count             = var.web_server.enabled != null || var.cloudwatch_logs.enabled ? 1 : 0
  name              = "/ecs/${lower(var.ecs_settings.run_type)}/${var.application_config.environment}-${var.application_config.name}-${var.web_server.name}"
  retention_in_days = var.cloudwatch_logs.retention_in_days
  tags              = local.tags
}
