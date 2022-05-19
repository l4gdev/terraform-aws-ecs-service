data "aws_secretsmanager_secret" "secrets" {
  for_each = var.list_of_secrets_in_secrets_manager_to_load
  name     = each.value
}

data "aws_secretsmanager_secret_version" "secrets" {
  for_each  = data.aws_secretsmanager_secret.secrets
  secret_id = each.value.id
}

resource "aws_secretsmanager_secret" "secret_env" {
  for_each = var.environment_variables_placeholder
  name     = lower("/${local.tags.Service}/secret/${each.value}")
  tags     = local.tags
}

