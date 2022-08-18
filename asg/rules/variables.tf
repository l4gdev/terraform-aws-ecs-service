variable "rule" {
  type = string
}
variable "ecs_target" {
  type = map(string)
}

variable "service" {
  type = string
}


variable "cluster_name" {
  type = string
}
variable "service_name" {
  type = string
}