## Requirements

No requirements.

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                                                  | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudwatch_event_rule.rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)                   | resource    |
| [aws_cloudwatch_event_target.ecs_scheduled_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource    |
| [aws_cloudwatch_log_group.task_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)           | resource    |
| [aws_codedeploy_app.deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_app)                               | resource    |
| [aws_codedeploy_deployment_config.foo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codedeploy_deployment_config)      | resource    |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)                                    | resource    |
| [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)                    | resource    |
| [aws_iam_role.ecs_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                       | resource    |
| [aws_iam_role_policy.ecs_events_run_task_with_any_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)  | resource    |
| [aws_lb_listener_rule.web_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule)                          | resource    |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)                                | resource    |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                           | data source |

## Inputs

| Name                                                                                                                                    | Description                                                                                              | Type                                                                                                                                                                                                                                         | Default | Required |
|-----------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| <a name="input_application_config"></a> [application\_config](#input\_application\_config)                                              | n/a                                                                                                      | <pre>object({<br>    name = string,<br>    domain = string,<br>    cpu = number,<br>    memory = number,<br>    image = string,<br>    environments = list(object({<br>      name = string,<br>      value = string<br>    }))<br>  })</pre> | n/a     |   yes    |
| <a name="input_aws_alb_listener_rule_condition"></a> [aws\_alb\_listener\_rule\_condition](#input\_aws\_alb\_listener\_rule\_condition) | Example [{ type = "host\_header", values = ["google.com"] }, { type = "path\_pattern", values = ["/"] }] | <pre>list(object({<br>    type = string<br>    values = list(string)<br>  }))</pre>                                                                                                                                                          | n/a     |   yes    |
| <a name="input_cron_run_type_settings"></a> [cron\_run\_type\_settings](#input\_cron\_run\_type\_settings)                              | schedule\_expression = cron(0 20 * * ? *) or rate(5 minutes) //                                          | <pre>object({<br>    job_name = string<br>    schedule_expression = string<br>    task_count = number<br>    task_command = list(string)<br>  })</pre>                                                                                       | n/a     |   yes    |
| <a name="input_ecs_settings"></a> [ecs\_settings](#input\_ecs\_settings)                                                                | n/a                                                                                                      | <pre>object({<br>    ecs_launch_type = string,<br>    ecs_cluster_name = string,<br>    run_type = string,<br>    lang = string,<br>  })</pre>                                                                                               | n/a     |   yes    |
| <a name="input_network_configuration"></a> [network\_configuration](#input\_network\_configuration)                                     | n/a                                                                                                      | <pre>object({<br>    alb_listener_arn = string<br>    vpc_id = string<br>  })</pre>                                                                                                                                                          | n/a     |   yes    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                          | n/a                                                                                                      | <pre>object({<br>    stack = string<br><br>  })</pre>                                                                                                                                                                                        | n/a     |   yes    |

## Outputs

No outputs.
