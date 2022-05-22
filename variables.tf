variable "ecs_settings" {
  type = object({
    ecs_launch_type  = string,
    ecs_cluster_name = string,
    run_type         = string,
    lang             = string,
  })
  validation {
    condition     = contains(["FARGATE", "EC2"], var.ecs_settings.ecs_launch_type)
    error_message = "ECS launch type can only be FARGATE or EC2."
  }
  validation {
    condition     = contains(["WEB", "WORKER", "CRON"], var.ecs_settings.run_type)
    error_message = "Run type can be WEB, WORKER, CRON."
  }
  validation {
    condition     = contains(["PHP", "NODE"], var.ecs_settings.lang)
    error_message = "Lang can be set to PHP or NODE."
  }
}

variable "desired_count" {
  type        = number
  default     = 1
  description = ""
}

variable "scheduling_strategy" {
  type        = string
  default     = "REPLICA"
  description = "Scheduling strategy to use for the service.  The valid values are REPLICA and DAEMON. Defaults to REPLICA. Note that Tasks using the Fargate launch type or the CODE_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy."
  validation {
    condition     = contains(["REPLICA", "DAEMON"], var.scheduling_strategy)
    error_message = "The valid values are REPLICA and DAEMON."
  }
}

variable "application_config" {
  type = object({
    name         = string,
    cpu          = number,
    memory       = number,
    image        = string,
    port         = number
    environments = any
  })
}

variable "health_checks" {
  type = list(object({
    enabled             = bool
    healthy_threshold   = number
    interval            = number
    matcher             = string
    path                = string
    timeout             = number
    unhealthy_threshold = number
  }))
  default = [
    {
      enabled             = true
      healthy_threshold   = 5
      interval            = 10
      matcher             = 200
      path                = "/"
      timeout             = 10
      unhealthy_threshold = 5
    }
  ]
}

variable "cron" {
  type = object({
    settings         = any,
    execution_script = string
  })
  default = {
    settings = [
      #      name                = ""
      #      execution_script    = ""
      #      schedule_expression = ""
      #      task_command        = []
    ]
    execution_script = ""
  }
  description = "schedule_expression = cron(0 20 * * ? *) or rate(5 minutes) // "
}

variable "worker_configuration" {
  type = object({
    execution_script = string
    args             = string
  })
  default = {
    execution_script = ""
    args             = ""
  }
}

variable "alb_listener_arn" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
  #  validation {
  #    condition =  var.ecs_settings.ecs_launch_type == "FARGATE" ? 1 : 0
  #    error_message = "Fargate launch type requires subnets."
  #  }
  default = []
}

variable "security_groups" {
  type    = list(string)
  default = []
}

variable "aws_alb_listener_rule_conditions" {
  default = []

  type = list(object({
    type   = string
    values = list(string)
  }))

  description = "Example [{ type = \"host_header\", values = [\"google.com\"] }, { type = \"path_pattern\", values = [\"/\"] }] "

  validation {
    condition = alltrue([
      for o in var.aws_alb_listener_rule_conditions : contains([
        "host_header", "path_pattern"
      ], o.type)
    ])
    error_message = "Type have to be host_header or path_pattern."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment_variables_placeholder" {
  type        = set(string)
  default     = []
  description = "List of names of secret envs for example [\"MYSQL_PASSWORD\"]. That module will create placeholders at AWS secret manager that you will have to fulfil. the list of ARNs is available at output."
}

variable "list_of_secrets_in_secrets_manager_to_load" {
  type    = set(string)
  default = []
}

variable "service_policy" {
  type        = string
  description = "please use aws_iam_policy_document to define your policy"
  default     = ""
}
