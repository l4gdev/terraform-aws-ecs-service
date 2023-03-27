locals {
  tags = merge({
    Service = var.application_config.name
    Type    = lower(var.ecs_settings.run_type)
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


  secrets_mapped = local.check_if_secretmanager_json_load_not_empty

  task_app_configuration = {
    WEB    = concat([local.web_standard_container_configuration], var.web_server.enabled == true ? [local.webserver_container_configuration] : [])
    NLB    = concat([local.nlb_standard_container_configuration], var.web_server.enabled == true ? [local.webserver_container_configuration] : [])
    WORKER = [local.worker_standard_container_configuration],
    CRON   = [local.worker_standard_container_configuration],
  }
  datadog_sidecar               = concat([local.datadog_fargate_sidecar], [local.task_app_configuration[var.ecs_settings.run_type]])
  running_container_definitions = var.ecs_settings.ecs_launch_type == "FARGATE" && var.fargate_datadog_sidecar_parameters.key != null ? jsonencode(local.datadog_sidecar) : jsonencode(local.task_app_configuration[var.ecs_settings.run_type])
}
