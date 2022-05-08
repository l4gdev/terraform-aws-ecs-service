resource "aws_secretsmanager_secret" "secret_env" {
  for_each = var.secret_environments_placeholder
  name     = lower("/${var.tags.Environment}/${var.tags.Service}/secret/${each.value}")
}


variable "list_of_secrets_in_secrets_manager_to_load" {
  type    = set(string)
  default = []
}

data "aws_secretsmanager_secret" "secrets" {
  for_each = var.list_of_secrets_in_secrets_manager_to_load
  name     = each.value
}

data "aws_secretsmanager_secret_version" "secrets" {
  for_each  = data.aws_secretsmanager_secret.secrets
  secret_id = each.value.id
}
