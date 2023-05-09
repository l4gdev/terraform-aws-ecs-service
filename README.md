# L4G ECS module

## Supported features 
* Web server apps with ALB
* ALB listener rules registrations.
* TCP/UDP servers with NLB
* Workers.
* Cron jobs.
* EC2 or FARGATE launch type.
* Autoscaling
* Volume mounts
* Webserver as a sidecar container
* Secrets from AWS Secrets Manager



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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_asg"></a> [asg](#module\_asg) | ./asg | n/a |
| <a name="module_cron"></a> [cron](#module\_cron) | ./cron/ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.task_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.task_log_group_webserver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.service_net](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.service_web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.service_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_task_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.service_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_events_run_task_with_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.get_s3_envs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ssm_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener.network_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.web-app-advance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.web-app-simple](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.app_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.network_lb_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_s3_object.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [local_file.secrets](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_iam_policy_document.placeholder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_deregistration_delay"></a> [alb\_deregistration\_delay](#input\_alb\_deregistration\_delay) | The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds | `number` | `30` | no |
| <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn) | The ARN of the listener to which to attach the routing rule. | `string` | `""` | no |
| <a name="input_alb_slow_start"></a> [alb\_slow\_start](#input\_alb\_slow\_start) | The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds.The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds. | `number` | `0` | no |
| <a name="input_application_config"></a> [application\_config](#input\_application\_config) | n/a | <pre>object({<br>    name                   = string,<br>    environment            = string,<br>    cpu                    = optional(number, 0),<br>    memory                 = optional(number, 0),<br>    image                  = string,<br>    entrypoint             = optional(list(string), null)<br>    cmd                    = optional(list(string), null)<br>    port                   = optional(number)<br>    environments_variables = any<br>  })</pre> | n/a | yes |
| <a name="input_aws_alb_listener_rule_conditions"></a> [aws\_alb\_listener\_rule\_conditions](#input\_aws\_alb\_listener\_rule\_conditions) | Example [{ type = "host\_header", values = ["google.com"] }, { type = "path\_pattern", values = ["/"] }] | <pre>list(object({<br>    type   = string<br>    values = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_aws_alb_listener_rule_conditions_advanced"></a> [aws\_alb\_listener\_rule\_conditions\_advanced](#input\_aws\_alb\_listener\_rule\_conditions\_advanced) | A list of maps describing the conditions of the rule. The order in which conditions are specified is not significant. Any condition block with a type of path-pattern or host-header must include a values block. For any other condition type, only one values block can be specified. For more information, see the AWS documentation on Listener Rules. Example: | <pre>list(object({<br>    name = string<br>    rules = list(object({<br>      type             = string<br>      values           = list(string)<br>      http_header_name = optional(string, null)<br>    }))<br>    auth = optional(object({<br>      type                                = string<br>      authorization_endpoint              = optional(string, null)       # oidc<br>      client_id                           = optional(string, null)       # oidc<br>      client_secret                       = optional(string, null)       # oidc<br>      issuer                              = optional(string, null)       # oidc<br>      token_endpoint                      = optional(string, null)       # oidc<br>      user_info_endpoint                  = optional(string, null)       # oidc<br>      authentication_request_extra_params = optional(list(string), null) # cognito<br>      on_unauthenticated_request          = optional(string, null)       # cognito<br>      scope                               = optional(string, null)       # cognito<br>      session_cookie_name                 = optional(string, null)       # cognito<br>      session_timeout                     = optional(number, null)       # cognito<br>      user_pool_arn                       = optional(string, null)       # cognito<br>      user_pool_client_id                 = optional(string, null)       # cognito<br>      user_pool_domain                    = optional(string, null)       # cognito<br>    }), null)<br>  }))</pre> | `null` | no |
| <a name="input_cron"></a> [cron](#input\_cron) | Allows to set cron jobs using aws event bridge please check examples | <pre>object({<br>    settings = list(object({<br>      name                = string<br>      args                = list(string)<br>      schedule_expression = string<br>      desired_count       = optional(number, 1)<br>    })),<br>    execution_script = list(string)<br>  })</pre> | `null` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | Desired count will be ignored after first deployment | <pre>object({<br>    first_deployment_desired_count = optional(number, 1) # I have no idea<br>    minimum_healthy_percent        = optional(number, 50)<br>    maximum_healthy_percent        = optional(number, 200)<br>    enable_asg                     = optional(bool, false)<br>    auto_scaling = optional(object({<br>      minimum = number<br>      maximum = number<br>      rules = list(object({<br>        name                = string<br>        metric              = string<br>        metric_period       = number<br>        cooldown            = number<br>        threshold           = number<br>        period              = number<br>        comparison_operator = string<br>        statistic           = string<br>        evaluation_periods  = number<br>        scaling_adjustment  = number<br>      }))<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_docker_labels"></a> [docker\_labels](#input\_docker\_labels) | Docker labels to be added to the container. The labels map is a set of key/value pairs. Application container is named var.application\_config.name .To add labels to webserver you have to set container\_name to webserver name for example nginx. | <pre>list(object({<br>    container_name = string<br>    labels         = optional(map(string), {})<br>  }))</pre> | `[]` | no |
| <a name="input_ecs_settings"></a> [ecs\_settings](#input\_ecs\_settings) | n/a | <pre>object({<br>    ecs_launch_type  = string,<br>    ecs_cluster_name = string,<br>    run_type         = string,<br>  })</pre> | n/a | yes |
| <a name="input_enable_code_build"></a> [enable\_code\_build](#input\_enable\_code\_build) | Enable code build | `bool` | `false` | no |
| <a name="input_fargate_datadog_sidecar_parameters"></a> [fargate\_datadog\_sidecar\_parameters](#input\_fargate\_datadog\_sidecar\_parameters) | n/a | <pre>object({<br>    image   = string<br>    dd_site = string<br>    key     = string<br>  })</pre> | <pre>{<br>  "dd_site": "datadoghq.eu",<br>  "image": "public.ecr.aws/datadog/agent:latest",<br>  "key": null<br>}</pre> | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Health check configuration for the service. | <pre>list(object({<br>    enabled             = optional(bool, true)<br>    healthy_threshold   = number<br>    interval            = number<br>    matcher             = string<br>    path                = string<br>    timeout             = number<br>    unhealthy_threshold = number<br>  }))</pre> | <pre>[<br>  {<br>    "enabled": true,<br>    "healthy_threshold": 5,<br>    "interval": 10,<br>    "matcher": 200,<br>    "path": "/",<br>    "timeout": 10,<br>    "unhealthy_threshold": 5<br>  }<br>]</pre> | no |
| <a name="input_list_of_secrets_in_secrets_manager_to_load"></a> [list\_of\_secrets\_in\_secrets\_manager\_to\_load](#input\_list\_of\_secrets\_in\_secrets\_manager\_to\_load) | List of names of secret manager secrets to load by theirs name. Module will load all secrets from secret manager and put them to envs. | `set(string)` | `[]` | no |
| <a name="input_network_lb"></a> [network\_lb](#input\_network\_lb) | Network load balancer configuration | <pre>object({<br>    nlb_arn = string,<br>    port_configuration = set(object({<br>      protocol = string,<br>      port     = number<br>    }))<br>  })</pre> | <pre>{<br>  "nlb_arn": "",<br>  "port_configuration": []<br>}</pre> | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | The network mode to use for the tasks. The valid values are awsvpc, bridge, host, and none. If no network mode is specified, the default is bridge. | `string` | `null` | no |
| <a name="input_ordered_placement_strategy"></a> [ordered\_placement\_strategy](#input\_ordered\_placement\_strategy) | https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PlacementStrategy.html | <pre>list(object({<br>    type  = string<br>    field = optional(string, null)<br>  }))</pre> | <pre>[<br>  {<br>    "field": "attribute:ecs.availability-zone",<br>    "type": "spread"<br>  }<br>]</pre> | no |
| <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints) | Placement constraints for the task | <pre>list(object({<br>    type       = string<br>    expression = string<br>  }))</pre> | `[]` | no |
| <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days) | (Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire. | `number` | `30` | no |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | Scheduling strategy to use for the service.  The valid values are REPLICA and DAEMON. Defaults to REPLICA. Note that Tasks using the Fargate launch type or the CODE\_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy. | `string` | `"REPLICA"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Setting requires network\_mode to be set to awsvpc. | `list(string)` | `[]` | no |
| <a name="input_service_policy"></a> [service\_policy](#input\_service\_policy) | please use aws\_iam\_policy\_document to define your policy | `string` | `""` | no |
| <a name="input_store_secrets_at_s3"></a> [store\_secrets\_at\_s3](#input\_store\_secrets\_at\_s3) | Store secrets at s3 bucket, i dont recommend this option | <pre>object({<br>    enable      = bool<br>    bucket_name = string<br>    prefix_name = optional(string, "")<br>  })</pre> | <pre>{<br>  "bucket_name": "",<br>  "enable": false,<br>  "prefix_name": ""<br>}</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Setting requires network\_mode to be set to awsvpc. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource. | `map(string)` | `{}` | no |
| <a name="input_use_static_port_on_ec2"></a> [use\_static\_port\_on\_ec2](#input\_use\_static\_port\_on\_ec2) | If set to true, the service will use the random port on the EC2 instances. | `bool` | `false` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Volumes to attach to the container. This parameter maps to Volumes in the Create a container section of the Docker Remote API and the --volume option to docker run.  List of maps with keys: name, host\_path, container\_path, read\_only | `list(any)` | `[]` | no |
| <a name="input_volumes_mount_point"></a> [volumes\_mount\_point](#input\_volumes\_mount\_point) | Volumes mount point at host | <pre>list(object({<br>    sourceVolume  = string<br>    containerPath = string<br>    readOnly      = bool<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC. | `string` | n/a | yes |
| <a name="input_web_server"></a> [web\_server](#input\_web\_server) | n/a | <pre>object({<br>    enabled        = bool<br>    name           = optional(string, "nginx")<br>    container_port = optional(number, 80)<br>    host_port      = optional(number, 0)<br>    image          = optional(string, "nginx:latest")<br>    command        = optional(list(string), null)<br>    entrypoint     = optional(list(string), null)<br>  })</pre> | <pre>{<br>  "enabled": false<br>}</pre> | no |
| <a name="input_worker_configuration"></a> [worker\_configuration](#input\_worker\_configuration) | Allows to set worker configuration | <pre>object({<br>    binary           = optional(string, "node")<br>    execution_script = optional(string, "")<br>    args             = optional(string, "")<br>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_s3_secrets"></a> [s3\_secrets](#output\_s3\_secrets) | n/a |
| <a name="output_task_iam_role_arn"></a> [task\_iam\_role\_arn](#output\_task\_iam\_role\_arn) | n/a |
| <a name="output_task_iam_role_name"></a> [task\_iam\_role\_name](#output\_task\_iam\_role\_name) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
