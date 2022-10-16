locals {
  assets_api_cron_worker_configuration = [
    {
      name                = "youtube:channels:sync"
      args                = "youtube:channels:sync"
      schedule_expression = "cron(0 2,10 * * ? *)"
      desired_count       = 1
    },
    {
      name                = "youtube:videos:sync"
      args                = "youtube:videos:sync"
      schedule_expression = "cron(0 3,11 * * ? *)"
      desired_count       = 1
    },
   ]
}

module "asset-cron-fargate" {
  source  = "registry.terraform.io/l4gdev/ecs-service/aws"
  version = "0.3.4"

  application_config = {
    name                   = "cron-${var.application_name}",
    cpu                    = 0,
    memory                 = 1200,
    port                   = 0
    image                  = var.image,
    environment            = var.environment
    environments_variables = local.app_envs
  }
  list_of_secrets_in_secrets_manager_to_load = local.list_of_secrets_in_secrets_manager_to_load

  ecs_settings = {
    ecs_launch_type  = "EC2",
    ecs_cluster_name = local.terraform_env.ecs_cluster.name,
    run_type         = "CRON",
    lang             = "STANDARD",
  }

  cron = {
    settings         = local.assets_api_cron_worker_configuration,
    execution_script = local.execution_script
  }

  tags = {
    Environment = var.environment
    Service     = var.application_name
  }
  security_groups = [local.terraform_env.ecs_cluster.security_group_id]
  subnets         = local.terraform_env.vpc.private_subnets
  vpc_id          = local.terraform_env.vpc.vpc_id
  service_policy  = data.aws_iam_policy_document.app_policy.json
  deployment = {}
}
