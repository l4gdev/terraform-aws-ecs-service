resource "aws_iam_role" "ecs-execution" {
  name = lower("${var.tags.Environment}-${var.tags.Service}-ecs-task-execution-role")
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs-execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs-execution.name
}


resource "aws_iam_role_policy" "ssm_access" {
  role = aws_iam_role.ecs-execution.name
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "kms:Decrypt"
        ],
        Resource : [
          "arn:aws:kms:*"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetSecretValue",
        ],
        Resource : [for x in local.check_if_secretmanager_json_load_not_empty : x.valueFrom]
      }
    ]
  })
}

################# Service role #################

resource "aws_iam_role" "service" {
  name = lower("${var.tags.Environment}-${var.tags.Service}-ecs-task-service-role")
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "",
        Effect : "Allow",
        Principal : {
          Service : ["ecs-tasks.amazonaws.com"]
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "service" {
  count  = var.service_policy == "{}" ? 0 : 1
  role   = aws_iam_role.service.name
  policy = var.service_policy
}

variable "service_policy" {
  type        = string
  description = "please use aws_iam_policy_document to define your policy"
  default     = "{}"
}
