locals {
  nlb_port_map = { for x in var.network_lb.port_configuration : "${x.protocol}-${tostring(x.port)}" => {
    protocol = x.protocol,
    port     = x.port
  } }
}

resource "aws_lb_listener" "network_lb_listener" {
  for_each          = aws_lb_target_group.network_lb_target
  load_balancer_arn = var.network_lb.nlb_arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = each.value.arn
  }
  depends_on = [aws_lb_target_group.network_lb_target]
}


resource "aws_lb_target_group" "network_lb_target" {
  for_each    = local.nlb_port_map
  name        = lower("${var.application_config.name}-${each.key}")
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = var.ecs_settings.ecs_launch_type == "FARGATE" ? "ip" : "instance"
  vpc_id      = var.vpc_id
  tags        = var.tags
}


