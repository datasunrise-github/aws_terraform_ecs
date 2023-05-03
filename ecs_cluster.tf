# Create an ECS Cluster

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.deployment_name}-cluster"
    tags = {
    Name        = "${var.deployment_name}-ecs"
    Environment = var.deployment_name
  }
}

# Task Definition
locals {
  fargate_mssql_dictionary = var.dictionary_db_type == "mssql" ? "true" : "false"
  fargate_mssql_audit      = var.audit_db_type == "mssql" ? "true" : "false"
  audit_db_address         = length(regexall("aurora-postgresql|aurora-mysql", var.audit_db_type)) != 0 ? "${join("", aws_rds_cluster.ds_audit_db_cluster.*.endpoint)}" : "${join("", aws_db_instance.audit_db.*.address)}"
  HourlyBillingLic         = "aT3Ma4BfGhCzDzhAerfmTq8yGS1Zwm4uLPio8Rv1CdDBhbwF0Lzwzh+aEyFaz+hoFnoqnwzDynZ8L4QRH1WDrg==:0:{\"CustomerName\":\"aws\",\"AWSMetering\":\"true\"}"
  ds_license_key           = var.ds_license_type == "BYOL" ? var.ds_license_key : local.HourlyBillingLic
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.deployment_name}-task"

  container_definitions = jsonencode(
  [
    {
      "name": "${var.deployment_name}-container",
      "image": "${var.image}",
      "cpu": "${var.container_cpu}",
      "memory": "${var.container_memory}",
      "essential": true,
      "environment" : [
              {"name" : "DICTIONARY_TYPE",                 "value"  : "${var.dictionary_db_type}"},
              {"name" : "DICTIONARY_HOST",                 "value"  : "${aws_db_instance.dictionary_db.address}"},
              {"name" : "DICTIONARY_PORT",                 "value"  : "${var.dictionary_db_port}"},
              {"name" : "DICTIONARY_DB_NAME",              "value"  : "${var.dictionary_db_name}"},
              {"name" : "DICTIONARY_LOGIN",                "value"  : "${var.db_username}"},
              {"name" : "DICTIONARY_PASS",                 "value"  : "${var.db_password}"},
              {"name" : "AUDIT_TYPE",                      "value"  : "${var.audit_db_type}"},
              {"name" : "AUDIT_HOST",                      "value"  : "${local.audit_db_address}"},
              {"name" : "AUDIT_PORT",                      "value"  : "${var.audit_db_port}"},
              {"name" : "AUDIT_DB_NAME",                   "value"  : "${var.audit_db_name}"},
              {"name" : "AUDIT_LOGIN",                     "value"  : "${var.db_username}"},
              {"name" : "AUDIT_PASS",                      "value"  : "${var.db_password}"},
              {"name" : "BACKEND_PORT",                    "value"  : "${var.ds_backend_port}"},
              {"name" : "ENABLE_SSH_SERVER",               "value"  : "${var.enable_ssh_server}"},
              {"name" : "SSH_PASS",                        "value"  : "${var.ssh_password}"},
              {"name" : "BUCKET_NAME",                     "value"  : "${var.s3_bucket_name}"},
              {"name" : "UPLOAD_LOGS_ON_SHUTDOWN",         "value"  : "1"},
              {"name" : "UPLOAD_CORE_ON_SHUTDOWN",         "value"  : "1"},
              {"name" : "AF_GENERATE_NATIVE_DUMPS",        "value"  : "${var.af_generate_native_dumps}"},
              {"name" : "FARGATE_MSSQL_AUDIT",             "value"  : "${local.fargate_mssql_audit}"},
              {"name" : "FARGATE_MSSQL_DICTIONARY",        "value"  : "${local.fargate_mssql_dictionary}"},
              {"name" : "DS_LICENSE_TYPE",                 "value"  : "${var.ds_license_type}"},
              {"name" : "DS_LICENSE_KEY",                  "value"  : "${local.ds_license_key}"},
              {"name" : "AWS_CLI_PROXY",                   "value"  : "${var.aws_cli_proxy}"},
              {"name" : "TDB_TYPE",                        "value"  : "${var.ds_instance_type}"},
              {"name" : "TDB_HOST",                        "value"  : "${var.ds_instance_host}"},
              {"name" : "TDB_PORT",                        "value"  : "${var.ds_instance_port}"},
              {"name" : "TDB_NAME",                        "value"  : "${var.ds_instance_database_name}"},
              {"name" : "TDB_LOGIN",                       "value"  : "${var.ds_instance_login}"},
              {"name" : "TDB_PASSWORD",                    "value"  : "${var.ds_instance_password}"},
              {"name" : "TDB_ENCRYPTION",                  "value"  : "${var.tdb_instance_encryption}"},
              {"name" : "DS_ADMIN_PASSWORD",               "value"  : "${var.ds_admin_password}"},
              {"name" : "DEPLOYMENT_NAME",                 "value"  : "${var.deployment_name}"},
              {"name" : "DS_SERVER_NAME_PREFIX",           "value"  : "${var.ds_prefix}"},
              {"name" : "CUSTOM_ORACLE_WALLET_AWS_BUCKET", "value"  : "${var.tbd_oracle_wallet_bucket}"}
          ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
            "awslogs-region": "${data.aws_region.current.name}",
            "awslogs-stream-prefix": "${var.deployment_name}"
          }
        },
      "portMappings": [
        {
          "containerPort": "${var.container_port}",
          "ContainerProxyPort": "${var.container_proxy_port}"
        }
      ]
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "${var.container_memory}"
  cpu                      = "${var.container_cpu}"
  # runtime_platform {
  #   operating_system_family = "LINUX"
  #   cpu_architecture        = "X86_64"
  # }
  execution_role_arn       = aws_iam_role.role.arn
  task_role_arn            = aws_iam_role.role.arn

  tags = {
    Name        = "${var.deployment_name}-ecs-td"
    Environment = var.deployment_name
  }
}

data "aws_ecs_task_definition" "main-tf" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

# Create an ECS Service
resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.deployment_name}-ecs-service"
  cluster              = "${aws_ecs_cluster.aws-ecs-cluster.id}"
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main-tf.revision)}"
  launch_type          = "FARGATE" //"FARGATE" does not support 'DAEMON' strategy
  desired_count        = 2 # Set up the number of containers to 3
  force_new_deployment = true
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200

  health_check_grace_period_seconds = 60

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets          = "${data.aws_subnet.targetcidr.*.id}"
    assign_public_ip = true
    security_groups  = [
      aws_security_group.ecssg.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "${var.deployment_name}-container"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.ListenerHTTPS, aws_lb_target_group.lb_target_group, aws_db_instance.dictionary_db, aws_db_instance.audit_db]
}