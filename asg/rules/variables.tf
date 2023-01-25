variable "rule" {
  type = string
}
variable "ecs_target" {
  type = map(string)
}

variable "service" {
  type = string
}

variable "app_name" {
  type = string

}

variable "cluster_name" {
  type = string
}
