module "asg" {
  source       = "./asg"
  count        = var.deployment.enable_asg ? 1 : 0
  auto_scaling = var.deployment.auto_scaling
  cluster_name = var.ecs_settings.ecs_cluster_name
  service_name = "${var.application_config.environment}-${var.application_config.name}"
}