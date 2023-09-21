resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = lower("${local.tags.Service}-${substr(md5("${var.application_config.environment}-${var.application_config.name}"), 0, 8)}-ecs-task-execution-role")
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "",
        Effect : "Allow",
        Principal : {
          Service : "ecs-tasks.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
  tags = local.tags

}

resource "aws_iam_role_policy_attachment" "ecs-execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy" "ssm_access" {
  count = length(local.check_if_secretmanager_json_load_not_empty) > 0 && !var.store_secrets_at_s3.enable ? 1 : 0
  role  = aws_iam_role.ecs_task_execution_role.name
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
        Resource : [for x in local.check_if_secretmanager_json_load_not_empty : replace(x.valueFrom, ":${split(":", x.valueFrom)[7]}::", "")]
      }
    ]
  })
}

resource "aws_iam_role_policy" "get_s3_envs" {
  count = var.store_secrets_at_s3.enable ? 1 : 0
  role  = aws_iam_role.ecs_task_execution_role.name
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "s3:GetObject"
        ],
        Resource : [
          "arn:aws:s3:::${var.store_secrets_at_s3.bucket_name}${aws_s3_object.secrets[0].key}"
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "s3:GetBucketLocation"
        ],
        Resource : [
          "arn:aws:s3:::${var.store_secrets_at_s3.bucket_name}"
        ]
      }
    ]
  })
}

################# Service role #################
resource "aws_iam_role" "service_role" {
  name_prefix = lower("${local.tags.Service}-${substr(md5("${var.application_config.environment}-${var.application_config.name}"), 0, 8)}-ecs-task-service-role")
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
  tags = local.tags
}

################# Custom application policy ##################
resource "aws_iam_role_policy" "service" {
  role   = aws_iam_role.service_role.name
  policy = var.service_policy == "" ? data.aws_iam_policy_document.placeholder.json : var.service_policy
}

data "aws_iam_policy_document" "placeholder" {
  statement {
    effect    = "Deny"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::PERMISION_PLACEHOLDER"]
  }
}

output "task_iam_role_name" {
  value = aws_iam_role.service_role.name
}

output "task_iam_role_arn" {
  value = aws_iam_role.service_role.arn
}

##################
