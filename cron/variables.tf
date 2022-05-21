variable "task_definition_arn" {
  type = string
}

variable "ecs_settings" {

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
    execution_script    = string
  })
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
