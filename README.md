# L4G simple ECS module

 **!!work in progress!!** 

**Supported features:** 
1. Web server apps with ALB
   1. automatic ALB listener rules registrations.
2. TCP/UDP servers with NLB
3. Workers.
4. Cron jobs.
5. EC2 or FARGATE launch type.
6. Autoscaling



# Java app example 
```hcl
module "app" {
  source  = "registry.terraform.io/l4gdev/ecs-service/aws"
  version = "xxxxx"

  application_config = {
    name        = var.application_name
    environment = var.environment
    cpu         = 0,
    memory      = 0,
    port        = 5000
    image       = var.image,
    environments_variables = merge(
      local.app_envs,
    )
  }

  list_of_secrets_in_secrets_manager_to_load = []

  aws_alb_listener_rule_conditions = [
    {
      type   = "host_header",
      values = var.domains
    }
  ]

  health_checks = [
    {
      enabled             = true
      healthy_threshold   = 5
      interval            = 10
      matcher             = 200
      path                = "/api/v1/health"
      timeout             = 5
      unhealthy_threshold = 5
    }
  ]

  ecs_settings = {
    ecs_launch_type  = "EC2",
    ecs_cluster_name = local.ecs_cluster_name,
    run_type         = "WEB",
    lang             = "STANDARD",
  }

  alb_listener_arn         = data.terraform_remote_state.backend.outputs.alb_arn
  alb_deregistration_delay = 30

  tags = {
    Environment = var.environment
    Service     = var.application_name
  }

  service_policy = data.aws_iam_policy_document.app_policy.json
  vpc_id         = local.vpc.vpc_id

  deployment = {
    first_deployment_desired_count = 1
    minimum_healthy_percent        = 50
    maximum_healthy_percent        = 200
    enable_asg                     = false
  }
}
```

## Worker Example
```hcl
locals {
  worker_configuration = [
    {
      args          = "my:awesome:consumer",
      desired_count = 1,
    },
  ]
}

module "asset-workers" {
  source   = "registry.terraform.io/l4gdev/ecs-service/aws"
  version  = "xxxx"
  for_each = { for worker in local.worker_configuration : replace(worker.args, ":", "-") => worker }

  application_config = {
    name                   = "worker-${each.key}",
    cpu                    = 0,
    memory                 = 150,
    port                   = 0
    image                  = var.image,
    environment            = var.environment
    environments_variables = local.app_envs
  }
  deployment = {
    first_deployment_desired_count = 1
    minimum_healthy_percent        = 50
    maximum_healthy_percent        = 200
    enable_asg                     = true
    auto_scaling = {
      minimum = 1
      maximum = 10
      rules = [
        {
          name               = "cpu_scale_up"
          metric             = "CPUUtilization"
          statistic          = "Average"
          comparison_operator = "GreaterThanOrEqualToThreshold"
          metric_period      = 120
          cooldown           = 60
          threshold          = 40
          period             = 60
          evaluation_periods = 2 #datapoins
          scaling_adjustment = 2
          }, {
          name               = "cpu_scale_down"
          metric             = "CPUUtilization"
          statistic          = "Average"
          comparison_operator = "LessThanThreshold"
          metric_period      = 120
          cooldown           = 300
          threshold          = 20
          period             = 60
          evaluation_periods = 5
          scaling_adjustment = -1
        }
      ]
    }
  }

  list_of_secrets_in_secrets_manager_to_load = local.list_of_secrets_in_secrets_manager_to_load
  worker_configuration = {
    execution_script = local.execution_script
    args             = each.value["args"]
  }
  desired_count = each.value["desired_count"]

  ecs_settings = {
    ecs_launch_type  = "EC2",
    ecs_cluster_name = local.terraform_env.ecs_cluster.name,
    run_type         = "WORKER",
    lang             = "STANDARD",
  }

  tags = {
    Environment = var.environment
    Service     = var.application_name
  }
  security_groups = [local.terraform_env.ecs_cluster.security_group_id]
  subnets         = local.terraform_env.vpc.private_subnets
  vpc_id          = local.terraform_env.vpc.vpc_id
  service_policy  = data.aws_iam_policy_document.app_policy.json
}
```

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws)

## Modules

The following Modules are called:

### <a name="module_asg"></a> [asg](#module\_asg)

Source: ./asg

Version:

### <a name="module_cron"></a> [cron](#module\_cron)

Source: ./cron/

Version:

## Resources

The following resources are used by this module:

- [aws_cloudwatch_log_group.task_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) (resource)
- [aws_cloudwatch_log_group.task_log_group_nginx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) (resource)
- [aws_ecs_service.service_net](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_service.service_web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_service.service_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) (resource)
- [aws_iam_role.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy.ecs_events_run_task_with_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy.ssm_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy_attachment.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_lb_listener.network_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) (resource)
- [aws_lb_listener_rule.web-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) (resource)
- [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) (resource)
- [aws_lb_target_group.network_lb_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) (resource)
- [aws_secretsmanager_secret.secret_env](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) (resource)
- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_iam_policy_document.placeholder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) (data source)
- [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)
- [aws_secretsmanager_secret.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) (data source)
- [aws_secretsmanager_secret_version.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_application_config"></a> [application\_config](#input\_application\_config)

Description: n/a

Type:

```hcl
object({
    name                   = string,
    environment            = string,
    cpu                    = optional(number, 0),
    memory                 = optional(number, 0),
    image                  = string,
    nginx_image            = optional(string)
    port                   = optional(number)
    environments_variables = any
  })
```

### <a name="input_deployment"></a> [deployment](#input\_deployment)

Description: Desired count will be ignored after first deployment

Type:

```hcl
object({
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
```

### <a name="input_ecs_settings"></a> [ecs\_settings](#input\_ecs\_settings)

Description: n/a

Type:

```hcl
object({
    ecs_launch_type  = string,
    ecs_cluster_name = string,
    run_type         = string,
    lang             = string,
  })
```

### <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)

Description: n/a

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_alb_deregistration_delay"></a> [alb\_deregistration\_delay](#input\_alb\_deregistration\_delay)

Description: The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds

Type: `number`

Default: `30`

### <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn)

Description: n/a

Type: `string`

Default: `""`

### <a name="input_alb_slow_start"></a> [alb\_slow\_start](#input\_alb\_slow\_start)

Description: The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds.The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds.

Type: `number`

Default: `0`

### <a name="input_aws_alb_listener_rule_conditions"></a> [aws\_alb\_listener\_rule\_conditions](#input\_aws\_alb\_listener\_rule\_conditions)

Description: Example [{ type = "host\_header", values = ["google.com"] }, { type = "path\_pattern", values = ["/"] }]

Type:

```hcl
list(object({
    type   = string
    values = list(string)
  }))
```

Default: `[]`

### <a name="input_cron"></a> [cron](#input\_cron)

Description: Allows to set cron jobs using aws event bridge please check examples

Type:

```hcl
object({
    settings = list(object({
      name                = string
      args                = string
      schedule_expression = string
      desired_count       = optional(number, 1)
    })),
    execution_script = string
  })
```

Default: `null`

### <a name="input_environment_variables_placeholder"></a> [environment\_variables\_placeholder](#input\_environment\_variables\_placeholder)

Description: List of names of secret envs for example ["MYSQL\_PASSWORD"]. That module will create placeholders at AWS secret manager that you will have to fulfil. the list of ARNs is available at output.

Type: `set(string)`

Default: `[]`

### <a name="input_fargate_datadog_sidecar_parameters"></a> [fargate\_datadog\_sidecar\_parameters](#input\_fargate\_datadog\_sidecar\_parameters)

Description: n/a

Type:

```hcl
object({
    image   = string
    dd_site = string
    key     = string
  })
```

Default:

```json
{
  "dd_site": "datadoghq.eu",
  "image": "public.ecr.aws/datadog/agent:latest",
  "key": null
}
```

### <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks)

Description: n/a

Type:

```hcl
list(object({
    enabled             = optional(bool, true)
    healthy_threshold   = number
    interval            = number
    matcher             = string
    path                = string
    timeout             = number
    unhealthy_threshold = number
  }))
```

Default:

```json
[
  {
    "enabled": true,
    "healthy_threshold": 5,
    "interval": 10,
    "matcher": 200,
    "path": "/",
    "timeout": 10,
    "unhealthy_threshold": 5
  }
]
```

### <a name="input_list_of_secrets_in_secrets_manager_to_load"></a> [list\_of\_secrets\_in\_secrets\_manager\_to\_load](#input\_list\_of\_secrets\_in\_secrets\_manager\_to\_load)

Description: n/a

Type: `set(string)`

Default: `[]`

### <a name="input_network_lb"></a> [network\_lb](#input\_network\_lb)

Description: n/a

Type:

```hcl
object({
    nlb_arn = string,
    port_configuration = set(object({
      protocol = string,
      port     = number
    }))
  })
```

Default:

```json
{
  "nlb_arn": "",
  "port_configuration": []
}
```

### <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy)

Description: Scheduling strategy to use for the service.  The valid values are REPLICA and DAEMON. Defaults to REPLICA. Note that Tasks using the Fargate launch type or the CODE\_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy.

Type: `string`

Default: `"REPLICA"`

### <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups)

Description: n/a

Type: `list(string)`

Default: `[]`

### <a name="input_service_policy"></a> [service\_policy](#input\_service\_policy)

Description: please use aws\_iam\_policy\_document to define your policy

Type: `string`

Default: `""`

### <a name="input_subnets"></a> [subnets](#input\_subnets)

Description: n/a

Type: `list(string)`

Default: `[]`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: n/a

Type: `map(string)`

Default: `{}`

### <a name="input_volumes"></a> [volumes](#input\_volumes)

Description: n/a

Type: `list(any)`

Default: `[]`

### <a name="input_volumes_mount_point"></a> [volumes\_mount\_point](#input\_volumes\_mount\_point)

Description: n/a

Type:

```hcl
list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
```

Default: `[]`

### <a name="input_worker_configuration"></a> [worker\_configuration](#input\_worker\_configuration)

Description: n/a

Type:

```hcl
object({
    binary           = optional(string, "node")
    execution_script = optional(string, "")
    args             = optional(string, "")
  })
```

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_task_iam_role_arn"></a> [task\_iam\_role\_arn](#output\_task\_iam\_role\_arn)

Description: n/a

### <a name="output_task_iam_role_name"></a> [task\_iam\_role\_name](#output\_task\_iam\_role\_name)

Description: n/a
