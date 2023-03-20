variable "task_definition_arn" {
  type = string
}

variable "ecs_settings" {
  type = any
}

variable "iam_role_arn" {
  type = string
}

variable "cron_settings" {
  type = object({
    name                = string
    args                = string
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
