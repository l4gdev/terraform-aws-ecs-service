# L4G ECS module
<img src="data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI1Ny45NTIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCA1Ny45NTIgMzIiPgogIDxnIGlkPSJHcm91cF81IiBkYXRhLW5hbWU9Ikdyb3VwIDUiIHRyYW5zZm9ybT0idHJhbnNsYXRlKC0yMDg1Ljk4NiAtMTgxMi45KSI+CiAgICA8cGF0aCBpZD0iUGF0aF82MyIgZGF0YS1uYW1lPSJQYXRoIDYzIiBkPSJNMjEwNi4xODMsMTgxMi45bC03LjYxOCwxNi4wOGgtNS44NzFsNy40ODUtMTYuMDhaIiBmaWxsPSIjZjFmMWY2Ii8+CiAgICA8cGF0aCBpZD0iUGF0aF82NCIgZGF0YS1uYW1lPSJQYXRoIDY0IiBkPSJNMjExMS4xNTUsMTgzOS4zMDd2NS41OTNoLTI1LjE2OWw3LjQ4Ni0xNi4wOGg1Ljg3MWwtNC45NjcsMTAuNDg3WiIgZmlsbD0iI2YxZjFmNiIvPgogICAgPHBhdGggaWQ9IlBhdGhfNjUiIGRhdGEtbmFtZT0iUGF0aCA2NSIgZD0iTTIxNDMuOTM3LDE4MjQuMDg2bC00LjIsNC44OTRoLTEyLjU4NHYtNC44OTRaIiBmaWxsPSIjZjFmMWY2Ii8+CiAgICA8cGF0aCBpZD0iUGF0aF82NiIgZGF0YS1uYW1lPSJQYXRoIDY2IiBkPSJNMjEzOS4xMjEsMTgzOS4zMDdoLTYuOTkxbDQuMTk1LTUuNTkzLDIuOC0zLjI2M1oiIGZpbGw9IiNmMWYxZjYiLz4KICAgIDxwYXRoIGlkPSJQYXRoXzY3IiBkYXRhLW5hbWU9IlBhdGggNjciIGQ9Ik0yMTQwLjUxOSwxODI4LjgybC0xLjQsMS42MzF2LS45MzJoLTUuNTkzdjQuMTk1aC01LjU5M3YtNC44OTRaIiBmaWxsPSIjZjFmMWY2Ii8+CiAgICA8cGF0aCBpZD0iUGF0aF82OCIgZGF0YS1uYW1lPSJQYXRoIDY4IiBkPSJNMjE0My45MzcsMTgxMi45djUuNTkzaC0yMi4zNzN2MTAuNDg3aC01LjU5M1YxODEyLjlaIiBmaWxsPSIjZjFmMWY2Ii8+CiAgICA8cGF0aCBpZD0iUGF0aF82OSIgZGF0YS1uYW1lPSJQYXRoIDY5IiBkPSJNMjEzMi4xMjksMTgzOS4zMDdsLTQuMiw1LjU5M2gtMTEuMTg2di01LjU5M2gyLjh2LTUuNTkzaC0yLjh2LTQuODk0aDUuNTkzdjEwLjQ4N1oiIGZpbGw9IiNmMWYxZjYiLz4KICAgIDxwYXRoIGlkPSJQYXRoXzcwIiBkYXRhLW5hbWU9IlBhdGggNzAiIGQ9Ik0yMTEwLjM3OCwxODE0LjN2MTQuNjgyaC02LjI5MloiIGZpbGw9IiNhMjAwMjkiLz4KICAgIDxwYXRoIGlkPSJQYXRoXzcxIiBkYXRhLW5hbWU9IlBhdGggNzEiIGQ9Ik0yMTExLjE1NSwxODI4LjgydjQuODk0aC04LjM5bDIuMS00Ljg5NFoiIGZpbGw9IiNhMjAwMjkiLz4KICA8L2c+Cjwvc3ZnPgo=" alt="L4G">

## Supported features 
1. Web server apps with ALB
   1. automatic ALB listener rules registrations.
2. TCP/UDP servers with NLB
3. Workers.
4. Cron jobs.
5. EC2 or FARGATE launch type.
6. Autoscaling
7. Volume mounts
8. Webserver as a sidecar container
9. Secrets from AWS Secrets Manager



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
   web_server             = {
    enabled = true
    name    = "nginx"
    image   = var.nginx_image
    port    = 80
  }
   
     placement_constraints = [
    {
      type       = "memberOf"
      expression = "attribute:ecs.instance-type =~ c5.*"
    }
  ]
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
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws)

- <a name="provider_local"></a> [local](#provider\_local)

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
- [aws_cloudwatch_log_group.task_log_group_webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) (resource)
- [aws_ecs_service.service_net](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_service.service_web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_service.service_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) (resource)
- [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) (resource)
- [aws_iam_role.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (resource)
- [aws_iam_role_policy.ecs_events_run_task_with_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy.get_s3_envs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy.ssm_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) (resource)
- [aws_iam_role_policy_attachment.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) (resource)
- [aws_lb_listener.network_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) (resource)
- [aws_lb_listener_rule.web-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) (resource)
- [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) (resource)
- [aws_lb_target_group.network_lb_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) (resource)
- [aws_s3_object.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) (resource)
- [local_file.secrets](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) (resource)
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
    entrypoint             = optional(list(string), null)
    cmd                    = optional(list(string), null)
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
  })
```

### <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)

Description: The ID of the VPC.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_alb_deregistration_delay"></a> [alb\_deregistration\_delay](#input\_alb\_deregistration\_delay)

Description: The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds

Type: `number`

Default: `30`

### <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn)

Description: The ARN of the listener to which to attach the routing rule.

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
    execution_script = list(string)
  })
```

Default: `null`

### <a name="input_docker_labels"></a> [docker\_labels](#input\_docker\_labels)

Description: Docker labels to be added to the container. The labels map is a set of key/value pairs. Application container is named var.application\_config.name .To add labels to webserver you have to set container\_name to webserver name for example nginx.

Type:

```hcl
list(object({
    container_name = string
    labels         = optional(map(string), {})
  }))
```

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

Description: Health check configuration for the service.

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

Description: List of names of secret manager secrets to load by theirs name. Module will load all secrets from secret manager and put them to envs.

Type: `set(string)`

Default: `[]`

### <a name="input_network_lb"></a> [network\_lb](#input\_network\_lb)

Description: Network load balancer configuration

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

### <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode)

Description: The network mode to use for the tasks. The valid values are awsvpc, bridge, host, and none. If no network mode is specified, the default is bridge.

Type: `string`

Default: `null`

### <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy)

Description: https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PlacementStrategy.html

Type:

```hcl
list(object({
    type  = string
    field = optional(string, null)
  }))
```

Default:

```json
[
  {
    "field": "attribute:ecs.availability-zone",
    "type": "spread"
  }
]
```

### <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints)

Description: Placement constraints for the task

Type:

```hcl
list(object({
    type       = string
    expression = string
  }))
```

Default: `[]`

### <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days)

Description: (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire.

Type: `number`

Default: `30`

### <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy)

Description: Scheduling strategy to use for the service.  The valid values are REPLICA and DAEMON. Defaults to REPLICA. Note that Tasks using the Fargate launch type or the CODE\_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy.

Type: `string`

Default: `"REPLICA"`

### <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups)

Description: Setting requires network\_mode to be set to awsvpc.

Type: `list(string)`

Default: `[]`

### <a name="input_service_policy"></a> [service\_policy](#input\_service\_policy)

Description: please use aws\_iam\_policy\_document to define your policy

Type: `string`

Default: `""`

### <a name="input_store_secrets_at_s3"></a> [store\_secrets\_at\_s3](#input\_store\_secrets\_at\_s3)

Description: Store secrets at s3 bucket, i dont recommend this option

Type:

```hcl
object({
    enable      = bool
    bucket_name = string
    prefix_name = optional(string, "")
  })
```

Default:

```json
{
  "bucket_name": "",
  "enable": false,
  "prefix_name": ""
}
```

### <a name="input_subnets"></a> [subnets](#input\_subnets)

Description: Setting requires network\_mode to be set to awsvpc.

Type: `list(string)`

Default: `[]`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `{}`

### <a name="input_use_static_port_on_ec2"></a> [use\_static\_port\_on\_ec2](#input\_use\_static\_port\_on\_ec2)

Description: If set to true, the service will use the random port on the EC2 instances.

Type: `bool`

Default: `false`

### <a name="input_volumes"></a> [volumes](#input\_volumes)

Description: Volumes to attach to the container. This parameter maps to Volumes in the Create a container section of the Docker Remote API and the --volume option to docker run.  List of maps with keys: name, host\_path, container\_path, read\_only

Type: `list(any)`

Default: `[]`

### <a name="input_volumes_mount_point"></a> [volumes\_mount\_point](#input\_volumes\_mount\_point)

Description: Volumes mount point at host

Type:

```hcl
list(object({
    sourceVolume  = string
    containerPath = string
    readOnly      = bool
  }))
```

Default: `[]`

### <a name="input_web_server"></a> [web\_server](#input\_web\_server)

Description: n/a

Type:

```hcl
object({
    enabled        = bool
    name           = optional(string, "nginx")
    container_port = optional(number, 80)
    host_port      = optional(number, 0)
    image          = optional(string, "nginx:latest")
    command        = optional(list(string), null)
    entrypoint     = optional(list(string), null)
  })
```

Default:

```json
{
  "enabled": false
}
```

### <a name="input_worker_configuration"></a> [worker\_configuration](#input\_worker\_configuration)

Description: Allows to set worker configuration

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

### <a name="output_s3_secrets"></a> [s3\_secrets](#output\_s3\_secrets)

Description: n/a

### <a name="output_task_iam_role_arn"></a> [task\_iam\_role\_arn](#output\_task\_iam\_role\_arn)

Description: n/a

### <a name="output_task_iam_role_name"></a> [task\_iam\_role\_name](#output\_task\_iam\_role\_name)

Description: n/a
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
