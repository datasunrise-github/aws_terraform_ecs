resource "aws_iam_role" "ExecutionRole" {
  name = "${var.deployment_name}-ecsTaskExecutionRole"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.deployment_name}-ecs-task-role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "policy" {
  name = "${var.deployment_name}-DataSunrise-VM-Policy"
  path = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecs:DescribeTasks",
                "ecs:DescribeServices",
                "ecs:ListClusters",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:PutMetricData",
                "ec2:DescribeSubnets",
                "rds:DescribeDBInstances",
                "rds:DescribeDBClusters",
                "aws-marketplace:MeterUsage",
                "secretsmanager:GetSecretValue",
                "logs:CreateLogStream",
                "events:PutEvents",
                "events:PutRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_appautoscaling_policy" "ds_autoscaling_policy" {
  name               = "${var.deployment_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    scale_in_cooldown  = 10
    scale_out_cooldown = 10
    target_value       = 80

  }
  depends_on = [
    aws_appautoscaling_target.ecs_target
  ]
}

resource "aws_iam_policy" "s3_access_policy" {
  name  = "${var.deployment_name}-S3AccessPolicy"
  path  = "/"
  count = var.s3_bucket_name != "" ? 1 : 0

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:HeadBucket",
                "s3:GetObject*",
                "s3:PutObject*",
                "s3:List*"
            ],
            "Resource": [ 
                "arn:aws:s3:::${var.s3_bucket_name}/*",
                "arn:aws:s3:::${var.s3_bucket_name}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "oracle_wallet_s3_access_policy" {
  name = "${var.deployment_name}-OracleWalletS3AccessPolicy"
  path = "/"
  count = var.s3_bucket_name != "" ? 1 : 0

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject*",
                "s3:List*"
            ],
            "Resource": [ 
                "arn:aws:s3:::${var.tbd_oracle_wallet_bucket}/*",
                "arn:aws:s3:::${var.tbd_oracle_wallet_bucket}"
            ]
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "dsecs-role-attach" {
  role       = aws_iam_role.ExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ds_autoscaling_policy-attach" {
  role       = aws_iam_role.ExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_iam_role_policy_attachment" "dsvm-task-role-attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role_policy_attachment" "s3-role-attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_access_policy[count.index].arn
  count      = var.s3_bucket_name != "" ? 1 : 0
}

resource "aws_iam_role_policy_attachment" "s3-oracle-wallet-role-attach" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.oracle_wallet_s3_access_policy[count.index].arn
  count      = var.s3_bucket_name != "" ? 1 : 0
}