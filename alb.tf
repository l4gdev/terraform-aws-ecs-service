resource "aws_lb_listener_rule" "web-app-simple" {
  count        = contains(["WEB"], var.ecs_settings.run_type) && var.aws_alb_listener_rule_conditions_advanced == null ? 1 : 0
  listener_arn = var.alb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  dynamic "condition" {
    for_each = var.aws_alb_listener_rule_conditions

    content {
      dynamic "host_header" {
        for_each = condition.value["type"] == "host_header" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value["type"] == "path_pattern" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "source_ip" {
        for_each = condition.value["type"] == "source_ip" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
    }
  }
  tags = local.tags
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.app
    ]
  }
}

locals {
  aws_alb_listener_rule_conditions_advance_remap = try({
    for condition in var.aws_alb_listener_rule_conditions_advanced : condition.name => condition
  }, {})
}


resource "aws_lb_listener_rule" "web-app-advance" {
  for_each     = var.aws_alb_listener_rule_conditions_advanced != null ? local.aws_alb_listener_rule_conditions_advance_remap : {}
  listener_arn = var.alb_listener_arn
  priority     = each.value["priority"]
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }

  dynamic "action" {
    for_each = each.value["auth"] != null ? [1] : []
    content {
      type = action.value["auth"]["type"]
      dynamic "authenticate_oidc" {
        for_each = action.value["auth"]["type"] == "authenticate_oidc" ? [1] : []
        content {
          authorization_endpoint = action.value["auth"]["authorization_endpoint"]
          client_id              = action.value["auth"]["client_id"]
          client_secret          = action.value["auth"]["client_secret"]
          issuer                 = action.value["auth"]["issuer"]
          token_endpoint         = action.value["auth"]["token_endpoint"]
          user_info_endpoint     = action.value["auth"]["user_info_endpoint"]
        }
      }
      dynamic "authenticate_cognito" {
        for_each = action.value["auth"]["type"] == "authenticate_cognito" ? [1] : []
        content {
          authentication_request_extra_params = action.value["auth"]["authentication_request_extra_params"]
          on_unauthenticated_request          = action.value["auth"]["on_unauthenticated_request"]
          scope                               = action.value["auth"]["scope"]
          session_cookie_name                 = action.value["auth"]["session_cookie_name"]
          session_timeout                     = action.value["auth"]["session_timeout"]
          user_pool_arn                       = action.value["auth"]["user_pool_arn"]
          user_pool_client_id                 = action.value["auth"]["user_pool_client_id"]
          user_pool_domain                    = action.value["auth"]["user_pool_domain"]
        }
      }
    }
  }

  dynamic "condition" {
    for_each = var.aws_alb_listener_rule_conditions

    content {
      dynamic "host_header" {
        for_each = condition.value["type"] == "host_header" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "http_header" {
        for_each = condition.value["type"] == "http_header" ? [1] : []
        content {
          http_header_name = condition.value["http_header_name"]
          values           = condition.value["values"]
        }
      }
      dynamic "path_pattern" {
        for_each = condition.value["type"] == "path_pattern" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
      dynamic "source_ip" {
        for_each = condition.value["type"] == "source_ip" ? [1] : []
        content {
          values = condition.value["values"]
        }
      }
    }
  }
  tags = local.tags
  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.app
    ]
  }
}
