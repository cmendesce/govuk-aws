/**
* ## Project: app-transition-postgresql
*
* RDS Transition PostgreSQL Primary instance
*/
variable "aws_region" {
  type        = "string"
  description = "AWS region"
  default     = "eu-west-1"
}

variable "stackname" {
  type        = "string"
  description = "Stackname"
}

variable "aws_environment" {
  type        = "string"
  description = "AWS Environment"
}

variable "instance_name" {
  type        = "string"
  description = "The RDS Instance Name."
  default     = ""
}

variable "cloudwatch_log_retention" {
  type        = "string"
  description = "Number of days to retain Cloudwatch logs for"
}

variable "username" {
  type        = "string"
  description = "PostgreSQL username"
}

variable "password" {
  type        = "string"
  description = "DB password"
}

variable "multi_az" {
  type        = "string"
  description = "Enable multi-az."
  default     = false
}

variable "snapshot_identifier" {
  type        = "string"
  description = "Specifies whether or not to create the database from this snapshot"
  default     = ""
}

# Resources
# --------------------------------------------------------------
terraform {
  backend          "s3"             {}
  required_version = "= 0.11.7"
}

provider "aws" {
  region  = "${var.aws_region}"
  version = "1.14.0"
}

module "transition-postgresql-primary_rds_instance" {
  source = "../../modules/aws/rds_instance"

  name                = "${var.stackname}-transition-postgresql-primary"
  engine_name         = "postgres"
  engine_version      = "9.6"
  default_tags        = "${map("Project", var.stackname, "aws_stackname", var.stackname, "aws_environment", var.aws_environment, "aws_migration", "transition_postgresql_primary")}"
  subnet_ids          = "${data.terraform_remote_state.infra_networking.private_subnet_rds_ids}"
  username            = "${var.username}"
  password            = "${var.password}"
  allocated_storage   = "120"
  instance_class      = "db.m4.large"
  instance_name       = "${var.stackname}-transition-postgresql-primary"
  multi_az            = "${var.multi_az}"
  security_group_ids  = ["${data.terraform_remote_state.infra_security_groups.sg_transition-postgresql-primary_id}"]
  event_sns_topic_arn = "${data.terraform_remote_state.infra_monitoring.sns_topic_rds_events_arn}"
  snapshot_identifier = "${var.snapshot_identifier}"
}

resource "aws_route53_record" "service_record" {
  zone_id = "${data.terraform_remote_state.infra_stack_dns_zones.internal_zone_id}"
  name    = "transition-postgresql-primary.${data.terraform_remote_state.infra_stack_dns_zones.internal_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${module.transition-postgresql-primary_rds_instance.rds_instance_address}"]
}

module "transition-postgresql-standby_rds_instance" {
  source = "../../modules/aws/rds_instance"

  name                       = "${var.stackname}-transition-postgresql-standby"
  default_tags               = "${map("Project", var.stackname, "aws_stackname", var.stackname, "aws_environment", var.aws_environment, "aws_migration", "transition_postgresql_standby")}"
  instance_class             = "db.m4.large"
  instance_name              = "${var.stackname}-transition-postgresql-standby"
  security_group_ids         = ["${data.terraform_remote_state.infra_security_groups.sg_transition-postgresql-standby_id}"]
  create_replicate_source_db = "1"
  replicate_source_db        = "${module.transition-postgresql-primary_rds_instance.rds_instance_id}"
  event_sns_topic_arn        = "${data.terraform_remote_state.infra_monitoring.sns_topic_rds_events_arn}"
}

resource "aws_route53_record" "replica_service_record" {
  zone_id = "${data.terraform_remote_state.infra_stack_dns_zones.internal_zone_id}"
  name    = "transition-postgresql-standby.${data.terraform_remote_state.infra_stack_dns_zones.internal_domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${module.transition-postgresql-standby_rds_instance.rds_replica_address}"]
}

module "alarms-rds-transition-postgresql-primary" {
  source         = "../../modules/aws/alarms/rds"
  name_prefix    = "${var.stackname}-transition-postgresql-primary"
  alarm_actions  = ["${data.terraform_remote_state.infra_monitoring.sns_topic_cloudwatch_alarms_arn}"]
  db_instance_id = "${module.transition-postgresql-primary_rds_instance.rds_instance_id}"
}

module "alarms-rds-transition-postgresql-standby" {
  source               = "../../modules/aws/alarms/rds"
  name_prefix          = "${var.stackname}-transition-postgresql-standby"
  alarm_actions        = ["${data.terraform_remote_state.infra_monitoring.sns_topic_cloudwatch_alarms_arn}"]
  db_instance_id       = "${module.transition-postgresql-standby_rds_instance.rds_replica_id}"
  replicalag_threshold = "300"
}

module "transition-postgresql-primary_log_exporter" {
  source                       = "../../modules/aws/rds_log_exporter"
  rds_instance_id              = "${module.transition-postgresql-primary_rds_instance.rds_instance_id}"
  s3_logging_bucket_name       = "${data.terraform_remote_state.infra_monitoring.aws_logging_bucket_id}"
  lambda_filename              = "../../lambda/RDSLogsToS3/RDSLogsToS3.zip"
  lambda_role_arn              = "${data.terraform_remote_state.infra_monitoring.lambda_rds_logs_to_s3_role_arn}"
  lambda_log_retention_in_days = "${var.cloudwatch_log_retention}"
}

module "transition-postgresql-standby_log_exporter" {
  source                       = "../../modules/aws/rds_log_exporter"
  rds_instance_id              = "${module.transition-postgresql-standby_rds_instance.rds_replica_id}"
  s3_logging_bucket_name       = "${data.terraform_remote_state.infra_monitoring.aws_logging_bucket_id}"
  lambda_filename              = "../../lambda/RDSLogsToS3/RDSLogsToS3.zip"
  lambda_role_arn              = "${data.terraform_remote_state.infra_monitoring.lambda_rds_logs_to_s3_role_arn}"
  lambda_log_retention_in_days = "${var.cloudwatch_log_retention}"
}

# Outputs
# --------------------------------------------------------------

output "transition-postgresql-primary_id" {
  value       = "${module.transition-postgresql-primary_rds_instance.rds_instance_id}"
  description = "transition-postgresql instance ID"
}

output "transition-postgresql-primary_resource_id" {
  value       = "${module.transition-postgresql-primary_rds_instance.rds_instance_resource_id}"
  description = "transition-postgresql instance resource ID"
}

output "transition-postgresql-primary_endpoint" {
  value       = "${module.transition-postgresql-primary_rds_instance.rds_instance_endpoint}"
  description = "transition-postgresql instance endpoint"
}

output "transition-postgresql-primary_address" {
  value       = "${module.transition-postgresql-primary_rds_instance.rds_instance_address}"
  description = "transition-postgresql instance address"
}

output "transition-postgresql-standby-endpoint" {
  value       = "${module.transition-postgresql-standby_rds_instance.rds_replica_endpoint}"
  description = "transition-postgresql replica instance endpoint"
}

output "transition-postgresql-standby-address" {
  value       = "${module.transition-postgresql-standby_rds_instance.rds_replica_address}"
  description = "transition-postgresql replica instance address"
}
