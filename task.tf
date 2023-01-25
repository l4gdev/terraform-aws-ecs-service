resource "aws_ecs_task_definition" "service" {
  family                   = "${var.application_config.environment}-${var.application_config.name}"
  execution_role_arn       = aws_iam_role.ecs-execution.arn
  network_mode             = var.network_mode == null ? var.ecs_settings.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge" : var.network_mode
  requires_compatibilities = [var.ecs_settings.ecs_launch_type]
  cpu                      = var.application_config.cpu == 0 ? "" : var.application_config.cpu
  memory                   = var.application_config.memory
  container_definitions    = local.running_container_definitions
  task_role_arn            = aws_iam_role.service.arn

  dynamic "volume" {
    for_each = var.volumes
    content {
      name      = volume.value.name
      host_path = try(volume.value.host_path, null)
      dynamic "efs_volume_configuration" {
        for_each = can(volume.value["efs_volume_configuration"]) ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
          dynamic "authorization_config" {
            for_each = can(efs_volume_configuration.value["authorization_config"]) ? [
              efs_volume_configuration.value.authorization_config
            ] : []
            content {
              iam             = lookup(authorization_config.value, "iam", null)
              access_point_id = lookup(authorization_config.value, "access_point_id", null)
            }
          }
        }
      }
    }
  }

  dynamic "runtime_platform" {
    for_each = var.ecs_settings.ecs_launch_type == "FARGATE" ? [1] : []

    content {
      cpu_architecture        = "X86_64"
      operating_system_family = "LINUX"
    }
  }
  tags = local.tags
}
