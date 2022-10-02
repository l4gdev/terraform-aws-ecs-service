locals {
  log_configuration = {
    logDriver = "awslogs",
    options = {
      awslogs-group         = aws_cloudwatch_log_group.task_log_group.name,
      awslogs-region        = data.aws_region.current.name,
      awslogs-create-group  = "true",
      awslogs-stream-prefix = "ecs",
    }
  }
    log_configuration_nginx = {
        logDriver = "awslogs",
        options = {
            awslogs-group         = aws_cloudwatch_log_group.task_log_group_nginx.0.name,
            awslogs-region        = data.aws_region.current.name,
            awslogs-create-group  = "true",
            awslogs-stream-prefix = "ecs",
        }
    }

  nginx_container_configuration = {
    name  = "nginx",
    image = var.application_config.nginx_image != null ? var.application_config.nginx_image : "nginx:latest"
    portMappings = [
      {
        "containerPort" = 80,
        "hostPort"      = 0,
        "protocol"      = "tcp"
      }
    ],
    links = [
      "${var.application_config.name}:app"
    ],
      logConfiguration = local.log_configuration_nginx,
  }

  web_standard_container_configuration = {
    name        = var.application_config.name,
    environment = local.env_mapped,
    secrets     = local.secrets_mapped,
    essential   = true,
    image       = var.application_config.image,
    portMappings = [
      {
        "containerPort" = var.application_config.port,
        "hostPort"      = 0,
        "protocol"      = "tcp"
      }
    ]
    logConfiguration = local.log_configuration,
    mountPoints      = var.volumes_mount_point
  }

  nlb_standard_container_configuration = {
    name        = var.application_config.name,
    environment = local.env_mapped,
    secrets     = local.secrets_mapped,
    essential   = true,
    image       = var.application_config.image,
    portMappings = [for p in var.network_lb.port_configuration : {
      containerPort = p.port,
      hostPort      = var.ecs_settings.ecs_launch_type == "FARGATE" ? p.port : 0,
      protocol      = lower(p.protocol)
    }]
    logConfiguration : local.log_configuration,
  }

  worker_standard_container_configuration = {
    name             = var.application_config.name,
    environment      = local.env_mapped,
    secrets          = local.secrets_mapped,
    essential        = true,
    image            = var.application_config.image,
    command          = var.worker_configuration.execution_script != "" ? [var.worker_configuration.binary, var.worker_configuration.execution_script, var.worker_configuration.args] : []
    logConfiguration = local.log_configuration,
    mountPoints      = var.volumes_mount_point
  }

  php_container_configuration = {
    name             = var.application_config.name,
    environment      = local.env_mapped,
    secrets          = local.secrets_mapped,
    essential        = true,
    image            = var.application_config.image,
    logConfiguration = local.log_configuration,
    mountPoints      = var.volumes_mount_point
  }

  datadog_fargate_sidecar = {
    name  = "datadog"
    image = var.fargate_datadog_sidecar_parameters.image,
    environment = [
      {
        name  = "DD_API_KEY"
        value = var.fargate_datadog_sidecar_parameters
      },
      {
        name  = "ECS_FARGATE",
        value = "true"
      },
      {
        name  = "DD_SITE"
        value = var.fargate_datadog_sidecar_parameters.dd_site
      }
    ],
  }
}

variable "fargate_datadog_sidecar_parameters" {
  type = object({
    image   = string
    dd_site = string
    key     = string
  })
  default = {
    image   = "public.ecr.aws/datadog/agent:latest",
    dd_site = "datadoghq.eu"
    key     = null
  }
}
