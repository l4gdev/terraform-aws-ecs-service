## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cron"></a> [cron](#module\_cron) | ./cron/ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.task_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.service_net](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.service_web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.service_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ecs_events_run_task_with_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.ssm_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ecs-execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener.network_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.web-app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.network_lb_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_secretsmanager_secret.secret_env](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.placeholder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_listener_arn"></a> [alb\_listener\_arn](#input\_alb\_listener\_arn) | n/a | `string` | `""` | no |
| <a name="input_application_config"></a> [application\_config](#input\_application\_config) | n/a | <pre>object({<br>    name         = string,<br>    cpu          = number,<br>    memory       = number,<br>    image        = string,<br>    port         = optional(number)<br>    environments = any<br>  })</pre> | n/a | yes |
| <a name="input_aws_alb_listener_rule_conditions"></a> [aws\_alb\_listener\_rule\_conditions](#input\_aws\_alb\_listener\_rule\_conditions) | Example [{ type = "host\_header", values = ["google.com"] }, { type = "path\_pattern", values = ["/"] }] | <pre>list(object({<br>    type   = string<br>    values = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_cron"></a> [cron](#input\_cron) | schedule\_expression = cron(0 20 * * ? *) or rate(5 minutes) // | <pre>object({<br>    settings         = any,<br>    execution_script = string<br>  })</pre> | <pre>{<br>  "execution_script": "",<br>  "settings": []<br>}</pre> | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | n/a | `number` | `1` | no |
| <a name="input_ecs_settings"></a> [ecs\_settings](#input\_ecs\_settings) | n/a | <pre>object({<br>    ecs_launch_type  = string,<br>    ecs_cluster_name = string,<br>    run_type         = string,<br>    lang             = string,<br>  })</pre> | n/a | yes |
| <a name="input_environment_variables_placeholder"></a> [environment\_variables\_placeholder](#input\_environment\_variables\_placeholder) | List of names of secret envs for example ["MYSQL\_PASSWORD"]. That module will create placeholders at AWS secret manager that you will have to fulfil. the list of ARNs is available at output. | `set(string)` | `[]` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | n/a | <pre>list(object({<br>    enabled             = bool<br>    healthy_threshold   = number<br>    interval            = number<br>    matcher             = string<br>    path                = string<br>    timeout             = number<br>    unhealthy_threshold = number<br>  }))</pre> | <pre>[<br>  {<br>    "enabled": true,<br>    "healthy_threshold": 5,<br>    "interval": 10,<br>    "matcher": 200,<br>    "path": "/",<br>    "timeout": 10,<br>    "unhealthy_threshold": 5<br>  }<br>]</pre> | no |
| <a name="input_list_of_secrets_in_secrets_manager_to_load"></a> [list\_of\_secrets\_in\_secrets\_manager\_to\_load](#input\_list\_of\_secrets\_in\_secrets\_manager\_to\_load) | n/a | `set(string)` | `[]` | no |
| <a name="input_network_lb"></a> [network\_lb](#input\_network\_lb) | n/a | <pre>object({<br>    nlb_arn = string,<br>    port_configuration = set(object({<br>      protocol = string,<br>      port     = number<br>    }))<br>  })</pre> | <pre>{<br>  "nlb_arn": "",<br>  "port_configuration": []<br>}</pre> | no |
| <a name="input_scheduling_strategy"></a> [scheduling\_strategy](#input\_scheduling\_strategy) | Scheduling strategy to use for the service.  The valid values are REPLICA and DAEMON. Defaults to REPLICA. Note that Tasks using the Fargate launch type or the CODE\_DEPLOY or EXTERNAL deployment controller types don't support the DAEMON scheduling strategy. | `string` | `"REPLICA"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `list(string)` | `[]` | no |
| <a name="input_service_policy"></a> [service\_policy](#input\_service\_policy) | please use aws\_iam\_policy\_document to define your policy | `string` | `""` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | n/a | `list(any)` | `[]` | no |
| <a name="input_volumes_mount_point"></a> [volumes\_mount\_point](#input\_volumes\_mount\_point) | n/a | <pre>list(object({<br>    sourceVolume = string<br>    containerPath = string<br>    readOnly = bool<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |
| <a name="input_worker_configuration"></a> [worker\_configuration](#input\_worker\_configuration) | n/a | <pre>object({<br>    execution_script = string<br>    args             = string<br>  })</pre> | <pre>{<br>  "args": "",<br>  "execution_script": ""<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_task_iam_role_arn"></a> [task\_iam\_role\_arn](#output\_task\_iam\_role\_arn) | n/a |
| <a name="output_task_iam_role_name"></a> [task\_iam\_role\_name](#output\_task\_iam\_role\_name) | n/a |