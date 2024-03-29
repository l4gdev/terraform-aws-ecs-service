variable "ecs_settings" {
  type = any
}

variable "iam_role_arn" {
  type = string
}

variable "cron_settings" {
  type = object({
    name                = string
    args                = list(string)
    schedule_expression = string
    desired_count       = number
    execution_script    = list(string)
  })
}

variable "application_config" {
  type = object({
    name                   = string,
    environment            = string,
    cpu                    = number,
    memory                 = number,
    image                  = string,
    port                   = optional(number)
    environments_variables = any
  })
}

variable "tags" {
  type = any
}

variable "launch_type" {
  type = any
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "ecs_execution_arn" {
  type = string
}

variable "network_mode" {
  type = string
}

variable "running_container_definitions" {
  type = string
}

variable "task_role_service_arn" {
  type = string
}

variable "volumes" {
  type = any
}

variable "capacity_provider_strategy" {
  default = []
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 1)
    base              = optional(number, 0)
  }))
}
