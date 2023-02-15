
locals {
  docker_labels_remap = { for v in var.docker_labels : v.container_name => v.labels }

  common_task_variables = {
    essential        = true
    name             = var.application_config.name,
    environment      = local.env_mapped,
    entryPoint       = var.application_config.entrypoint
    command          = var.application_config.cmd
    secrets          = var.store_secrets_at_s3.enable ? null : local.secrets_mapped
    environmentFiles = var.store_secrets_at_s3.enable ? local.environmentFiles : null
    image            = var.application_config.image
    mountPoints      = var.volumes_mount_point
    logConfiguration = local.log_configuration
    dockerLabels     = try(local.docker_labels_remap[var.application_config.name], {})
  }

  ######################### APP ##########################
  web_standard_container_configuration = merge(local.common_task_variables, {
    portMappings = [
      {
        containerPort = var.application_config.port,
        hostPort      = var.use_static_port_on_ec2 ? var.application_config.port : 0,
        protocol      = "tcp"
      }
    ]
  })

  nlb_standard_container_configuration = merge(local.common_task_variables, {
    portMappings = [for p in var.network_lb.port_configuration : {
      containerPort = p.port,
      hostPort      = var.ecs_settings.ecs_launch_type == "FARGATE" ? p.port : 0,
      protocol      = lower(p.protocol)
    }]
  })

  worker_standard_container_configuration = merge(local.common_task_variables, {
    command = try(var.worker_configuration.execution_script, "") != "" ? [var.worker_configuration.binary, var.worker_configuration.execution_script, var.worker_configuration.args] : try(var.application_config.cmd, [])
  })

  #################### LOG ##########################
  log_configuration = {
    logDriver = "awslogs",
    options = {
      awslogs-group         = aws_cloudwatch_log_group.task_log_group.name,
      awslogs-region        = data.aws_region.current.name,
      awslogs-create-group  = "true",
      awslogs-stream-prefix = "ecs",
    }
  }

  log_configuration_webserver = {
    logDriver = "awslogs",
    options = {
      awslogs-group         = try(aws_cloudwatch_log_group.task_log_group_webserver[0].name, ""),
      awslogs-region        = data.aws_region.current.name,
      awslogs-create-group  = "true",
      awslogs-stream-prefix = "ecs",
    }
  }
  ######################### SIDECAR ##########################
  webserver_container_configuration = {
    name  = var.web_server.name,
    image = var.web_server.image,
    portMappings = [
      {
        containerPort = var.web_server.container_port,
        hostPort      = var.use_static_port_on_ec2 ? var.web_server.host_port : 0,
        protocol      = "tcp"
      }
    ],
    links            = ["${var.application_config.name}:${var.application_config.name}"],
    logConfiguration = local.log_configuration_webserver,
    dockerLabels     = try(local.docker_labels_remap[var.web_server.name], {})
    command          = try(var.web_server.command, null)
    entryPoint       = try(var.web_server.entrypoint, null)
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
  ######################## OTHER #####################

  environmentFiles = [
    {
      value : try("arn:aws:s3:::${var.store_secrets_at_s3.bucket_name}${aws_s3_object.secrets[0].key}", ""),
      type : "s3"
    }
  ]


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
