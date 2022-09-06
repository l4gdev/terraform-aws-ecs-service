locals {
  tags = merge({
    Service = var.application_config.name
  }, var.tags)

  env_mapped = [
    for k, v in var.application_config.environments_variables :
    {
      name  = k,
      value = v
    }
  ]

  secretmanager_json_load = flatten([
    for k, v in data.aws_secretsmanager_secret_version.secrets :
    [
      for secret_name, _ in nonsensitive(jsondecode(v.secret_string)) : # marked as non sensitive as it is just name and ARN
      {
        name      = secret_name,
        valueFrom = "${v.arn}:${secret_name}::"
      }
    ]
  ])

  check_if_secretmanager_json_load_not_empty = length(local.secretmanager_json_load) > 0 ? tolist(local.secretmanager_json_load) : []

  decelerated_secretmanage_placeholders = [
    for k, n in aws_secretsmanager_secret.secret_env :
    {
      name      = k,
      valueFrom = n.arn
    }
  ]

  secrets_mapped = concat(local.decelerated_secretmanage_placeholders, local.check_if_secretmanager_json_load_not_empty)

  WEB = {
    STANDARD = local.web_standard_container_configuration,
    PHP      = [local.nginx_container_configuration, local.php_container_configuration],
  }

  NLB = {
    STANDARD = local.nlb_standard_container_configuration
  }

  task_app_configuration = {
    WEB    = local.WEB[var.ecs_settings.lang],
    NLB    = local.NLB[var.ecs_settings.lang],
    WORKER = [local.worker_standard_container_configuration],
    CRON   = [local.worker_standard_container_configuration],
  }
  datadog_sidecar = concat([local.datadog_fargate_sidecar], [local.task_app_configuration[var.ecs_settings.run_type]])
  running_container_definitions = var.ecs_settings.ecs_launch_type == "FARGATE" && var.fargate_datadog_sidecar_parameters.key != null ? jsonencode(local.datadog_sidecar) : jsonencode([local.task_app_configuration[var.ecs_settings.run_type]])
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.application_config.environment}-${var.application_config.name}"
  execution_role_arn       = aws_iam_role.ecs-execution.arn
  network_mode             = var.ecs_settings.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = [var.ecs_settings.ecs_launch_type]
  cpu                      = var.application_config.cpu == 0 ? "" : var.application_config.cpu
  memory                   = var.application_config.memory
  container_definitions    = local.running_container_definitions
  task_role_arn            = aws_iam_role.service.arn

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name
      dynamic "efs_volume_configuration" {
        for_each = can(volume.value["efs_volume_configuration"]) ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = can(efs_volume_configuration.value["authorization_config"]) ? [
              efs_volume_configuration.value.authorization_config
            ] : []
            content {
              iam             = lookup(authorization_config.value, "iam", null)
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
            }
          }
        }
      }
    }
  }

  dynamic "runtime_platform" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []

    content {
      cpu_architecture        = "X86_64"
      operating_system_family = "LINUX"
    }
  }
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "task_log_group" {
  name = "/ecs/${var.ecs_settings.run_type}/${var.application_config.environment}-${var.application_config.name}"
  tags = local.tags
}

