locals {
  log_configuration = {
    logDriver : "awslogs",
    options : {
      awslogs-group : aws_cloudwatch_log_group.task_log_group.name,
      awslogs-region : data.aws_region.current.name,
      awslogs-create-group : "true",
      awslogs-stream-prefix : "ecs",
    }
  }

  nginx_container_configuration = {
    name : "nginx",
    image : "nginx:latest"
    portMappings : [
      {
        "containerPort" : 80,
        "hostPort" : 0,
        "protocol" : "tcp"
      }
    ],
    links = [
      "${var.application_config.name}:php"
    ]
  }

  web_node_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    portMappings : [
      {
        "containerPort" : var.application_config.port,
        "hostPort" : 0,
        "protocol" : "tcp"
      }
    ]
    logConfiguration : local.log_configuration,
  }

  nlb_node_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    portMappings : [for p in var.network_lb.port_configuration : {
      containerPort : p.port,
      hostPort : var.ecs_settings.ecs_launch_type == "FARGATE" ? p.port : 0,
      protocol : lower(p.protocol)
    }]
    logConfiguration : local.log_configuration,
  }

  worker_node_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    command : ["node", var.worker_configuration.execution_script, var.worker_configuration.args]
    logConfiguration : local.log_configuration,
  }

  php_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    logConfiguration : local.log_configuration,
  }

}