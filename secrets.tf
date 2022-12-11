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

##################### s3 base secrets ####################
resource "aws_s3_object" "secrets" {
  count                  = var.store_secrets_at_s3.enable ? 1 : 0
  bucket                 = var.store_secrets_at_s3.bucket_name
  key                    = "${var.store_secrets_at_s3.prefix_name}/${local_file.secrets[0].filename}"
  source                 = local_file.secrets[0].filename
  source_hash            = md5(tostring(join("\n", local.files)))
  server_side_encryption = "aws:kms"
  depends_on             = [local_file.secrets]

  provisioner "local-exec" {
    command = "rm ${local_file.secrets[0].filename}"
  }
}

resource "local_file" "secrets" {
  count    = var.store_secrets_at_s3.enable ? 1 : 0
  content  = tostring(join("\n", local.files))
  filename = "${var.application_config.environment}-${var.application_config.name}-secrets.env"
}

locals {
  files = sensitive(flatten([
    for k, v in data.aws_secretsmanager_secret_version.secrets :
    [for secret_name, value in nonsensitive(jsondecode(v.secret_string)) : "${secret_name}=${value}"]
  ]))
}
