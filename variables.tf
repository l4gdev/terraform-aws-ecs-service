variable "ecs_settings" {
  type = object({
    ecs_launch_type  = string,
    ecs_cluster_name = string,
    run_type         = string,
  })
  validation {
    condition     = contains(["FARGATE", "EC2"], var.ecs_settings.ecs_launch_type)
    error_message = "ECS launch type can only be FARGATE or EC2."
  }
  validation {
    condition     = contains(["WEB", "WORKER", "CRON", "NLB"], var.ecs_settings.run_type)
    error_message = "Run type can be WEB, WORKER, CRON, NLB."
  }
}

variable "deployment" {
  type = object({
    first_deployment_desired_count = optional(number, 1) # I have no idea
    minimum_healthy_percent        = optional(number, 50)
    maximum_healthy_percent        = optional(number, 200)
    enable_asg                     = optional(bool, false)
    auto_scaling = optional(object({
      minimum = number
      maximum = number
      rules = list(object({
        name                = string
        metric              = string
        metric_period       = number
        cooldown            = number
        threshold           = number
        period              = number
        comparison_operator = string
        statistic           = string
        evaluation_periods  = number
        scaling_adjustment  = number
      }))
    }))
  })
  description = "Desired count will be ignored after first deployment"
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
    name                   = string,
    environment            = string,
    cpu                    = optional(number, 0),
    memory                 = optional(number, 0),
    image                  = string,
    entrypoint             = optional(list(string), null)
    cmd                    = optional(list(string), null)
    port                   = optional(number)
    environments_variables = any
  })
}

variable "web_server" {
  type = object({
    enabled        = bool
    name           = optional(string, "nginx")
    container_port = optional(number, 80)
    host_port      = optional(number, 0)
    image          = optional(string, "nginx:latest")
    command        = optional(list(string), null)
    entrypoint     = optional(list(string), null)
  })
  default = {
    enabled = false
  }
}

variable "docker_labels" {
  type = list(object({
    container_name = string
    labels         = optional(map(string), {})
  }))
  description = "Docker labels to be added to the container. The labels map is a set of key/value pairs. Application container is named var.application_config.name .To add labels to webserver you have to set container_name to webserver name for example nginx."
  default     = []
}


variable "alb_deregistration_delay" {
  type        = number
  default     = 30
  description = "The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds"
}

variable "alb_slow_start" {
  type        = number
  default     = 0
  description = "The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds.The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds."
}

variable "health_checks" {
  type = list(object({
    enabled             = optional(bool, true)
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
  description = "Health check configuration for the service."
}

variable "cron" {
  type = object({
    settings = list(object({
      name                = string
      args                = list(string)
      schedule_expression = string
      desired_count       = optional(number, 1)
    })),
    execution_script = list(string)
  })

  default     = null
  nullable    = true
  description = "Allows to set cron jobs using aws event bridge please check examples"
}

variable "worker_configuration" {
  type = object({
    binary           = optional(string, "node")
    execution_script = optional(string, "")
    args             = optional(string, "")
  })
  default     = null
  nullable    = true
  description = "Allows to set worker configuration"
}

variable "alb_listener_arn" {
  type        = string
  default     = ""
  description = "The ARN of the listener to which to attach the routing rule."
}

variable "use_static_port_on_ec2" {
  type        = bool
  default     = false
  description = "If set to true, the service will use the random port on the EC2 instances."
}

variable "network_mode" {
  type        = string
  default     = null
  nullable    = true
  description = "The network mode to use for the tasks. The valid values are awsvpc, bridge, host, and none. If no network mode is specified, the default is bridge."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC."
}

variable "subnets" {
  type        = list(string)
  default     = []
  description = "Setting requires network_mode to be set to awsvpc."
}

variable "security_groups" {
  type        = list(string)
  default     = []
  description = "Setting requires network_mode to be set to awsvpc."
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
        "host_header",
        "path_pattern",
        "source_ip"
      ], o.type)
    ])
    error_message = "Type have to be host_header or path_pattern."
  }
}

variable "aws_alb_listener_rule_conditions_advanced" {
  type = list(object({
    name = string
    rules = list(object({
      type             = string
      values           = list(string)
      http_header_name = optional(string, null)
    }))
    auth = optional(object({
      type                                = string
      authorization_endpoint              = optional(string, null)       # oidc
      client_id                           = optional(string, null)       # oidc
      client_secret                       = optional(string, null)       # oidc
      issuer                              = optional(string, null)       # oidc
      token_endpoint                      = optional(string, null)       # oidc
      user_info_endpoint                  = optional(string, null)       # oidc
      authentication_request_extra_params = optional(list(string), null) # cognito
      on_unauthenticated_request          = optional(string, null)       # cognito
      scope                               = optional(string, null)       # cognito
      session_cookie_name                 = optional(string, null)       # cognito
      session_timeout                     = optional(number, null)       # cognito
      user_pool_arn                       = optional(string, null)       # cognito
      user_pool_client_id                 = optional(string, null)       # cognito
      user_pool_domain                    = optional(string, null)       # cognito
    }), null)
  }))
  default     = null
  description = "A list of maps describing the conditions of the rule. The order in which conditions are specified is not significant. Any condition block with a type of path-pattern or host-header must include a values block. For any other condition type, only one values block can be specified. For more information, see the AWS documentation on Listener Rules. Example: "
}


variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resource."
}

variable "list_of_secrets_in_secrets_manager_to_load" {
  type        = set(string)
  default     = []
  description = "List of names of secret manager secrets to load by theirs name. Module will load all secrets from secret manager and put them to envs."
}

variable "store_secrets_at_s3" {

  type = object({
    enable      = bool
    bucket_name = string
    prefix_name = optional(string, "")
  })
  default = {
    enable      = false
    bucket_name = ""
    prefix_name = ""
  }
  description = "Store secrets at s3 bucket, i dont recommend this option"
}

variable "service_policy" {
  type        = string
  description = "please use aws_iam_policy_document to define your policy"
  default     = ""
}

variable "network_lb" {
  type = object({
    nlb_arn = string,
    port_configuration = set(object({
      protocol = string,
      port     = number
    }))
  })
  default = {
    nlb_arn            = "",
    port_configuration = []
  }
  description = "Network load balancer configuration"
}

variable "volumes" {
  type        = list(any)
  default     = []
  description = "Volumes to attach to the container. This parameter maps to Volumes in the Create a container section of the Docker Remote API and the --volume option to docker run.  List of maps with keys: name, host_path, container_path, read_only"
}

variable "volumes_mount_point" {
  type = list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
  default     = []
  description = "Volumes mount point at host"
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
}

variable "ordered_placement_strategy" {
  type = list(object({
    type  = string
    field = optional(string, null)
  }))
  default = [{
    type  = "spread"
    field = "attribute:ecs.availability-zone"

  }]
  description = "https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PlacementStrategy.html"
}

variable "placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))
  default     = []
  description = "Placement constraints for the task"
}

variable "enable_code_build" {
  type        = bool
  default     = false
  description = "Enable code build"
}

variable "capacity_provider_strategy" {
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
}
