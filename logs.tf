#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "task_log_group" {
  name              = "/ecs/${var.ecs_settings.run_type}/${var.application_config.environment}-${var.application_config.name}"
  retention_in_days = var.retention_in_days
  tags              = local.tags
}
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "task_log_group_nginx" {
  count             = var.application_config.nginx_image != null ? 1 : 0
  name              = "/ecs/${var.ecs_settings.run_type}/${var.application_config.environment}-${var.application_config.name}-nginx"
  retention_in_days = var.retention_in_days
  tags              = local.tags
}

