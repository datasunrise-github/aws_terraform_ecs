# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DataSunrise Cluster for Amazon Web Services
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Please replace xxxxxxxxx with values that correspond to your environment
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

variable "deployment_name" {
  description = "Name that will be used as the prefix to the resources' names that will be created by the Terraform script (only in lower case, not more than 15 symbols and not less than 5 symbols)"
  default     = "xxxxxxxxx"
}

# ------------------------------------------------------------------------------
# Network Configuration
# ------------------------------------------------------------------------------

variable "vpc_id" {
  description = "Prefered VPC Id"
  #Must be the VPC Id of an existing Virtual Private Cloud.
  default     = "xxxxxxxxx"
}

variable "admin_location_CIDR" {
  description = "IP address range that can be used access port 22, for appliance configuration access to the EC2 instances."
  #Must be a valid IP CIDR range of the form x.x.x.x/x.
  default     = "0.0.0.0/0"
}

variable "user_location_CIDR" {
  description = "IP address range that can be used access port 11000, for appliance configuration access to the DataSunrise console and database proxy."
  #Must be a valid IP CIDR range of the form x.x.x.x/x.
  default     = "0.0.0.0/0"
}

variable "vpc_CIDR" {
  default = "172.31.0.0/16"
}

# ------------------------------------------------------------------------------
# Container Configuration
# ------------------------------------------------------------------------------

variable "certificate" {
  description = "Update with the certificate ARN from Certificate Manager, which must exist in the same region."
  default     = "arn:aws:acm:region:accountid:certificate/certificateid"
}

variable "container_cpu" {
  description   = "# 256 (.25 vCPU) - Available memory values: 0.5GB, 1GB, 2GB"
                  # 512 (.5 vCPU) - Available memory values: 1GB, 2GB, 3GB, 4GB
                  # 1024 (1 vCPU) - Available memory values: 2GB, 3GB, 4GB, 5GB, 6GB, 7GB, 8GB
                  # 2048 (2 vCPU) - Available memory values: Between 4GB and 16GB in 1GB increments
                  # 4096 (4 vCPU) - Available memory values: Between 8GB and 30GB in 1GB increments
  # AllowedValues = ["512","1024","2048","4096"]
  type = number
  default       = 2048
}

variable "container_memory" {
  description = "# 0.5GB, 1GB, 2GB - Available cpu values: 256 (.25 vCPU)"
                 # 1GB, 2GB, 3GB, 4GB - Available cpu values: 512 (.5 vCPU)
                 # 2GB, 3GB, 4GB, 5GB, 6GB, 7GB, 8GB - Available cpu values: 1024 (1 vCPU)
                 # Between 4GB and 16GB in 1GB increments - Available cpu values: 2048 (2 vCPU)
                 # Between 8GB and 30GB in 1GB increments - Available cpu values: 4096 (4 vCPU)
  default     = 4096
}

variable "ds_backend_port" {
  description = "the same ContainerPort"
  default     = "443"
}

variable "container_port" {
  default     = 443
}

variable "container_proxy_port" {
  description = "If container will be used as proxy - specify a port number that will be used for proxy."
  type        = number
  default     = 443
}

variable "image" {
  description = "Update with the Docker image. 'You can use images in the Docker Hub registry or specify other repositories (repository-url/image:tag).'"
                 #Default: 123456789012.dkr.ecr.region.amazonaws.com/image:tag"
  default     = "datasunrise/datasunrise:latest"
}

variable "enable_ssh_server" {
  description   = "Connectin to VM on ssh"
  # AllowedValues = ["true", "false"]
  default       = "false"
}

variable "ssh_password" {
  description = "(Optional if EnableSSHServer equals false) Enter password for ssh connect"
  default     = ""
}

variable "af_generate_native_dumps" {
  description   = "(Optional) Generate native dumps on VM and uploading to S3 bucket."
  default       = "1"
  # AllowedValues = ["1", "0"]
}

# ------------------------------------------------------------------------------
# DataSunrise Configuration
# ------------------------------------------------------------------------------

variable "ds_admin_password" {
  description = "DataSunrise admin's password"
  default     = "xxxxxxxxx"
}

variable "ds_license_type" {
  description   = "Preferred licensing type. If you select BYOL licensing, you must enter a valid license key into DSLicenseKey field."
  # AllowedValues = ["HourlyBilling", "BYOL"]
  default       = "BYOL"
}

variable "ds_license_key" {
  description = "The DataSunrise license key. !!!Important. For correct key substitution, if there are double quotes in the key, then it is necessary to make a concatenation using a backslash (\")!!!"
  default     = "Do not change this field if you are using hourly billing"
}

variable "s3_bucket_name" {
  description = "(Optional) Name of the S3 bucket for DataSunrise backups & logs. If empty, the backup uploading will not be configured."
  default     = ""
}

variable "ds_prefix" {
  description = "(Optional) Prefix for DS logical server name. If not specified it will be added automatically as ds."
  default     = ""
}

# ------------------------------------------------------------------------------
# Dictionary & Audit Database Configuration
# ------------------------------------------------------------------------------

variable "dictionary_db_type" {
  description = "postgresql, mysql, mssql"
  default     = "postgresql"
}

variable "dictionary_db_class" {
  description = "The database instance class that allocates the computational, network, and memory capacity required by planned workload of this database instance."
                # "Classes t3.small, t3.medium and t3.large are not available for MSSQL."
  default     = "db.t3.medium"
}

variable "dictionary_db_name" {
  description = "Dictionary DB name"
  default     = "dsdictionary"
}

variable "dictionary_db_port" {
  description = "Dictionary DB port"
  default     = "5432"
}

variable "multi_az_dictionary" {
  description  = "Dictionary RDS Multi-AZ"
  default      = "false"
  # AllowedValues = ["true", "false"]
}

variable "dictionary_db_storage_size" {
  description = "The size of the database (Gb), minimum restriction by AWS is 20GB"
  default     = 20
}

variable "audit_db_type" {
  description = "Type Audit Database: postgresql, mysql, mssql, aurora-mysql, aurora-postgresql"
  default     = "postgresql"
}

variable "audit_db_class" {
  description = "The database instance class that allocates the computational, network, and memory capacity required by planned workload of this database instance."
                # "Classes t3.small, t3.medium and t3.large are not available for MSSQL."
  default     = "db.t3.medium"
}

variable "audit_db_name" {
  description = "Audit DB name"
  default     = "dsaudit"
}

variable "audit_db_port" {
  description = "Audit DB port"
  default     = "5432"
}

variable "multi_az_audit" {
  description   = "Dictionary RDS Multi-AZ"
  default       = "false"
  # AllowedValues = ["true", "false"]
}

variable "audit_db_storage_size" {
  description = "The size of the database (Gb), minimum restriction by AWS is 20GB"
  default     = 20
}

variable "db_username" {
  description = "The database administrator account username. Must begin with a letter and contain only alphanumeric characters."
  default     = "dsuser"
}

variable "db_password" {
  description = "The database administrator account password."
    #The database administrator account password.
    #You can also specify the arn of the secret to retrieve the password from AWS Secrets Manager.
    #For example: arn:aws:secretsmanager:us-east-1:123456789012:secret:mysecret-aBcD12.
  type        = string
  default     = "xxxxxxxxx"
}

variable "db_storage_type" {
  description = "Storage type General Purpose SSD: gp2, gp3"
  default = "gp3"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Dictionary and Audit subnets. Must be a part of mentioned VPC. Please be sure that you select at least two subnets."
    #IN CASE YOU NEED TO ADD MORE SUBNET IDS, JUST ADD IT AS NEW ELEMENT OF THE LIST BELOW USING COMMA TO SEPARATE THEM
    #IF NUMBER OF SUBNETS IS MORE THEN DEFAULT YOU HAVE TO ADD THE CORRESPONDING AMOUNT OF VARIABLES IN MAIN.TF
  default     = ["xxxxxxxxx", "xxxxxxxxx"]
}

# ------------------------------------------------------------------------------
# Target Database Configuration
# ------------------------------------------------------------------------------

variable "ds_instance_port" {
  description = "Target Database Instance Port"
  default     = "xxxxxxxxx"
}

variable "ds_instance_host" {
  description = "Target Database Instance Host"
  default     = "xxxxxxxxx"
}

variable "ds_instance_type" {
  description   = "Target Database Instance Type"
  # Allowedvalues = ["aurora mysql", "aurora postgresql", "db2", "greenplum", "hive", "mariadb", "mysql", "mssql", "netezza", "oracle", "postgresql", "redshift",
  # "teradata", "sap hana", "vertica", "mongo", "dynamo", "impala", "cassandra"]
  default       = "xxxxxxxxx"
}

variable "ds_instance_database_name" {
  description = "Target Database internal database name e.g. master for MSSQL or postgres for PostgreSQL"
  default     = "xxxxxxxxx"
}

variable "ds_instance_login" {
  description = "Target Database Login"
  default     = "xxxxxxxxx"
}

variable "ds_instance_password" {
  description = "Target Database Password"
  default     = "xxxxxxxxx"
}

variable "tdb_instance_encryption" {
  description = "(Optional) Use Encryption when connecting to the database (supported only for Aurora MySQL, MySQL, MariaDB, Cassandra, DB2, DynamoDB, MongoDB, Oracle, SAP HANA)"
  default = "false"
  # AllowedValues = ["true", "false"]
}

variable "tbd_oracle_wallet_bucket" {
  description = "(Optional) The name of the S3 bucket that contains Oracle Wallet files."
  default     = ""
}

# ------------------------------------------------------------------------------
# Auto Scaling Group Configuration
# ------------------------------------------------------------------------------

variable "containers_count" {
  description = "Count of Containers DataSunrise Server to be launched."
  default     = 1
}

variable "ASGLB_subnets" {
  type        = list(string)
  description = "Load Balancer and EC2 instances subnets. Must be a part of mentioned VPC."
  #IN CASE YOU NEED TO ADD MORE SUBNET IDS, JUST ADD IT AS NEW ELEMENT OF THE LIST BELOW USING COMMA TO SEPARATE THEM.
  #IF NUMBER OF SUBNETS IS MORE THEN DEFAULT YOU HAVE TO ADD THE CORRESPONDING AMOUNT OF VARIABLES IN MAIN.TF
  default = ["xxxxxxxxx", "xxxxxxxxx"]
}

variable "ds_autoscaling_group_cooldown" {
  description = "Seconds to wait, after a scaling activity, to do any further action"
  default     = 300
}

# ------------------------------------------------------------------------------
# LoadBalancer Configuration
# ------------------------------------------------------------------------------

variable "elb_scheme" {
  description = "For load balancers attached to an Amazon VPC, this parameter can be used to specify the type of load balancer to use. Specify 'true' to create an internal load balancer with a DNS name that resolves to private IP addresses or 'false' to create an internet-facing load balancer with a publicly resolvable DNS name, which resolves to public IP addresses."
  # AllowedValues = "true", "false"
  default     = "false"
  
}

variable "ds_load_balancer_hc_healthy_threshold" {
  description = "Number of consecutive health probe failure required before flagging the instance as healthy"
  default     = 3
}

variable "ds_load_balancer_hc_unhealthy_threshold" {
  description = "Number of consecutive health probe failure required before flagging the instance as unhealthy"
  default     = 3
}

variable "ds_load_balancer_hc_interval" {
  description = "Health check interval"
  default     = 10
}

variable "ds_load_balancer_hc_timeout" {
  description = "Health check timeout"
  default     = 5
}

# ------------------------------------------------------------------------------
# Proxy Options
# ------------------------------------------------------------------------------

variable "aws_cli_proxy" {
  description = "(Optional) In some cases of using private networks it is necessary to set up proxy for AWS CLI (PutMetrics/S3). For example http://[username[:password]@]<proxy host>:<proxy port>"
  default     = ""
}