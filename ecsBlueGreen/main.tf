variable "name" {

}

variable "deployment_config_name" {

}

variable "ecs_service_name" {

}

variable "termination_wait_time_in_minutes" {

}

variable "ecs_cluster_name" {
  type = string
}


variable "env_name" {
  default = ""
}

variable "alb" {
  type = object({
    main_listener     = string
    main_target_group = string
    test_listener     = string
    test_target_group = string
  })
}

resource "aws_iam_role" "deployment" {
  name = "${var.env_name}-deployment-role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "codedeploy.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.deployment.name
}

resource "aws_codedeploy_deployment_group" "ecs" {
  app_name               = var.name
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = "deployment-group-${var.ecs_service_name}"
  service_role_arn       = aws_iam_role.deployment.arn
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
    }
  }
  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {

      prod_traffic_route {
        listener_arns = [
          var.alb.main_listener
        ]
      }

      target_group {
        name = var.alb.main_target_group
      }

      target_group {
        name = var.alb.test_target_group
      }

      test_traffic_route {
        listener_arns = [
          var.alb.test_listener
        ]
      }

    }
  }
}

