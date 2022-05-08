
variable "task_definition_arn" {

}
variable "ecs_settings" {

}
variable "iam_role_arn" {

}
variable "crone_settings" {
  type = object({
    name                = string
    args                = string
    schedule_expression = string
    desired_count       = number
    execution_script    = string
  })
}

variable "application_config" {

}
