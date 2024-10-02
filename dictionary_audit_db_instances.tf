# Create Database Subnets
resource "aws_db_subnet_group" "ds_db_subnet_group" {
  name        = "${var.deployment_name}-db-subnet-group"
  description = "RDS database subnet group for DataSunrise configuration storage"
  #ENTER-SUBNET-IDS-LIST HERE. YOU CAN SEE AN EXAMPLE HOW TO GET FIRST, SECOND ELEMENT FROM THE LIST DEFINED IN VARIAVLES.TF
  subnet_ids  = var.db_subnet_ids
}

# Create Database Instances 
locals {
  rds_dictionary_type = var.dictionary_db_type == "postgresql" ? "postgres" : var.dictionary_db_type
  rds_audit_type      = var.audit_db_type      == "postgresql" ? "postgres" : var.audit_db_type

  dictionary_rds_server_engine = {
    postgres = "postgres",
    mssql    = "sqlserver-se",
    mysql    = "mysql"
  }
  dictionary_rds_engine_version = {
    postgres = "15",
    mssql    = "15.00",
    mysql    = "8.0"
  }
  audit_rds_server_engine = {
    postgres          = "postgres",
    mssql             = "sqlserver-se",
    mysql             = "mysql",
    aurora-mysql      = "aurora-mysql",
    aurora-postgresql = "aurora-postgresql"
  }
  audit_rds_engine_version = {
    postgres          = "15",
    mssql             = "15.00",
    mysql             = "8.0",
    aurora-mysql      = "8.0",
    aurora-postgresql = "15"
  }
  db_license_model = {
    postgres          = "postgresql-license",
    mssql             = "license-included",
    mysql             = "general-public-license",
    aurora-mysql      = null,
    aurora-postgresql = null
  }
  db_parameter_group_family = {
    postgres          = "postgres15",
    mssql             = "sqlserver-se-15.0",
    mysql             = "mysql8.0",
    aurora-mysql      = "aurora-mysql8.0",
    aurora-postgresql = "aurora-postgresql15"
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  count     = can(regex("^arn:aws:secretsmanager:", var.db_password)) ? 1 : 0
  secret_id = var.db_password
}

resource "aws_db_instance" "dictionary_db" {
  identifier             = "${var.deployment_name}-dictionary"
  db_name                = var.dictionary_db_type != "mssql" ? var.dictionary_db_name : null
  engine                 = lookup(local.dictionary_rds_server_engine, local.rds_dictionary_type)
  engine_version         = lookup(local.dictionary_rds_engine_version, local.rds_dictionary_type)
  instance_class         = var.dictionary_db_class
  license_model          = lookup(local.db_license_model, local.rds_dictionary_type)
  port                   = var.dictionary_db_port
  username               = var.db_username
  password               = can(regex("^arn:aws:secretsmanager:", var.db_password)) ? jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.db_password[0].secret_string))["password"] : var.db_password
  multi_az               = var.multi_az_dictionary
  allocated_storage      = var.dictionary_db_storage_size
  vpc_security_group_ids = [aws_security_group.ds_config_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.ds_db_subnet_group.name
  storage_encrypted      = true
  storage_type           = var.db_storage_type
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.ds_parameter_group_dictionary.name

  depends_on = [
    aws_db_subnet_group.ds_db_subnet_group,
    aws_security_group.ds_config_sg,
    aws_db_parameter_group.ds_parameter_group_dictionary
  ]
}

resource "aws_db_instance" "audit_db" {
  count                  = length(regexall("aurora-postgresql|aurora-mysql", local.rds_audit_type)) == 0 ? 1 : 0
  identifier             = "${var.deployment_name}-audit"
  db_name                = var.audit_db_type != "mssql" ? var.audit_db_name : null
  engine                 = lookup(local.audit_rds_server_engine, local.rds_audit_type)
  engine_version         = lookup(local.audit_rds_engine_version, local.rds_audit_type)
  instance_class         = var.audit_db_class
  license_model          = lookup(local.db_license_model, local.rds_audit_type)
  port                   = var.audit_db_port
  username               = var.db_username
  password               = can(regex("^arn:aws:secretsmanager:", var.db_password)) ? jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.db_password[0].secret_string))["password"] : var.db_password
  multi_az               = var.multi_az_dictionary
  allocated_storage      = var.audit_db_storage_size
  vpc_security_group_ids = [aws_security_group.ds_config_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.ds_db_subnet_group.name
  storage_encrypted      = true
  storage_type           = var.db_storage_type
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.ds_parameter_group_audit[count.index].name

  depends_on = [
    aws_db_subnet_group.ds_db_subnet_group,
    aws_security_group.ds_config_sg,
    aws_db_parameter_group.ds_parameter_group_audit
  ]
}

# Create Aurora Cluster And Instance
resource "aws_rds_cluster" "ds_audit_db_cluster" {
  count                           = length(regexall("aurora-postgresql|aurora-mysql", var.audit_db_type)) != 0 ? 1 : 0
  cluster_identifier              = "${var.deployment_name}-ds-audit-cluster"
  engine                          = lookup(local.audit_rds_server_engine, local.rds_audit_type)
  engine_version                  = lookup(local.audit_rds_engine_version, local.rds_audit_type)
  database_name                   = var.audit_db_name
  master_username                 = var.db_username
  master_password                 = can(regex("^arn:aws:secretsmanager:", var.db_password)) ? jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.db_password[0].secret_string))["password"] : var.db_password
  port                            = var.audit_db_port
  storage_encrypted               = true
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_db_subnet_group.ds_db_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.ds_config_sg.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.ds_parameter_group_cluster[count.index].name
}

resource "aws_rds_cluster_instance" "ds_audit_db_cluster_node" {
  count                = length(regexall("aurora-postgresql|aurora-mysql", var.audit_db_type)) != 0 ? 1 : 0
  identifier           = "${var.deployment_name}-ds-audit-node"
  cluster_identifier   = "${aws_rds_cluster.ds_audit_db_cluster[0].cluster_identifier}"
  instance_class       = var.audit_db_class
  engine               = aws_rds_cluster.ds_audit_db_cluster[count.index].engine
  engine_version       = aws_rds_cluster.ds_audit_db_cluster[count.index].engine_version
  db_subnet_group_name = aws_db_subnet_group.ds_db_subnet_group.name

  depends_on = [
    aws_db_subnet_group.ds_db_subnet_group,
    aws_security_group.ds_config_sg,
    aws_rds_cluster_parameter_group.ds_parameter_group_cluster
  ]
}

# Create Parameter Group
locals {
  parameters     = {
    mssql    = [{
      name         = "rds.force_ssl"
      value        = true
      apply_method = "pending-reboot"
      }],
    postgres = [{
      name         = "rds.force_ssl"
      value        = true
      apply_method = "pending-reboot"
      }],
    mysql    = [{
        name         = "character_set_server"
        value        = "utf8mb4"
        apply_method = "pending-reboot"
      },
      {
        name         = "collation_server"
        value        = "utf8mb4_bin"
        apply_method = "pending-reboot"
      },
      {
        name         = "log_bin_trust_function_creators"
        value        = "1"
        apply_method = "pending-reboot"
      }
      ],
    aurora-postgresql = [{
      name         = "rds.force_ssl"
      value        = true
      apply_method = "pending-reboot"
      }],
    aurora-mysql = [{
        name         = "character_set_server"
        value        = "utf8mb4"
        apply_method = "pending-reboot"
      },
      {
        name         = "collation_server"
        value        = "utf8mb4_bin"
        apply_method = "pending-reboot"
      },
      {
        name         = "log_bin_trust_function_creators"
        value        = "1"
        apply_method = "pending-reboot"
      }
      ]
  }
}

resource "aws_db_parameter_group" "ds_parameter_group_dictionary" {
  name        = "${var.deployment_name}-parameter-group-dict-${var.dictionary_db_type}"
  family      = lookup(local.db_parameter_group_family, local.rds_dictionary_type)
  description = "DS Parameter Group Configured By Terraform"

  dynamic "parameter" {
    for_each = lookup(local.parameters, local.rds_dictionary_type)
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_db_parameter_group" "ds_parameter_group_audit" {
  count       = length(regexall("aurora-postgresql|aurora-mysql", var.audit_db_type)) == 0 ? 1 : 0
  name        = "${var.deployment_name}-parameter-group-audit-${var.audit_db_type}"
  family      = lookup(local.db_parameter_group_family, local.rds_audit_type)
  description = "DS Parameter Group Configured By Terraform"

  dynamic "parameter" {
    for_each = lookup(local.parameters, local.rds_audit_type)
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_rds_cluster_parameter_group" "ds_parameter_group_cluster" {
  count       = length(regexall("aurora-postgresql|aurora-mysql", var.audit_db_type)) != 0 ? 1 : 0
  name        = "${var.deployment_name}-parameter-group-audit-${var.audit_db_type}"
  family      = lookup(local.db_parameter_group_family, local.rds_audit_type)
  description = "DS Parameter Group Configured By Terraform"

  dynamic "parameter" {
    for_each = lookup(local.parameters, local.rds_audit_type)
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = false
  }
}
