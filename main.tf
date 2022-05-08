locals {
  env_mapped     = [for k, v in var.application_config.environments : { name = k, value = v }]
  secrets_mapped = [for k,n in aws_secretsmanager_secret.secret_env : { name = k, valueFrom = n.arn }]

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
    logConfiguration : {
      logDriver : "awslogs",
      options : {
        awslogs-group : aws_cloudwatch_log_group.task_log_group.name,
        awslogs-region : data.aws_region.current.name,
        awslogs-create-group : "true",
        awslogs-stream-prefix : "ecs",
      }
    },
  }

  worker_node_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    command : ["node", var.worker_configuration.execution_script, var.worker_configuration.args]
    logConfiguration : {
      logDriver : "awslogs",
      options : {
        awslogs-group : aws_cloudwatch_log_group.task_log_group.name,
        awslogs-region : data.aws_region.current.name,
        awslogs-create-group : "true",
        awslogs-stream-prefix : "ecs",
      }
    },
  }

  php_container_configuration = {
    name : var.application_config.name,
    environment : local.env_mapped,
    secrets : local.secrets_mapped,
    essential : true,
    image : var.application_config.image,
    logConfiguration : {
      logDriver : "awslogs",
      options : {
        awslogs-group : aws_cloudwatch_log_group.task_log_group.name,
        awslogs-region : data.aws_region.current.name,
        awslogs-create-group : "true",
        awslogs-stream-prefix : "ecs",
      }
    },
  }

  WEB = {
    NODE = jsonencode([local.web_node_container_configuration]),
    PHP  = jsonencode([local.nginx_container_configuration, local.php_container_configuration]),
  }

  task_app_configuration = {
    WEB    = local.WEB[var.ecs_settings.lang],
    WORKER = jsonencode([local.worker_node_container_configuration]),
    CRON   = jsonencode([local.worker_node_container_configuration]),
  }

}

data "aws_caller_identity" "current" {}


resource "aws_ecs_task_definition" "service" {
  family                   = var.application_config.name
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  network_mode             = var.ecs_settings.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  requires_compatibilities = [var.ecs_settings.ecs_launch_type]
  cpu                      = var.application_config.cpu == 0 ? "" : var.application_config.cpu
  memory                   = var.application_config.memory
  container_definitions    = local.task_app_configuration[var.ecs_settings.run_type]

  dynamic "runtime_platform" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []
    content {
      cpu_architecture        = "X86_64"
      operating_system_family = "LINUX"
    }
  }

}


data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "task_log_group" {
  name = "/ecs/${var.ecs_settings.run_type}/${var.application_config.name}"
}

