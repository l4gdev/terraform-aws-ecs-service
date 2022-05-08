resource "aws_secretsmanager_secret" "secret_env" {
  for_each = var.secret_environments_placeholder
  name     = lower("/${var.tags.Environment}/${var.tags.Service}/secret/${each.value}")
}


