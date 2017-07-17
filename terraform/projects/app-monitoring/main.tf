# == Manifest: projects::app-monitoring
#
# Monitoring node
#
# === Variables:
#
# aws_region
# remote_state_bucket
# stackname
# ssh_public_key
#
# === Outputs:
#

variable "aws_region" {
  type        = "string"
  description = "AWS region"
  default     = "eu-west-1"
}

variable "remote_state_bucket" {
  type        = "string"
  description = "S3 bucket we store our terraform state in"
}

variable "stackname" {
  type        = "string"
  description = "Stackname"
}

variable "ssh_public_key" {
  type        = "string"
  description = "Default public key material"
}

# Resources
# --------------------------------------------------------------
terraform {
  backend          "s3"             {}
  required_version = "= 0.9.10"
}

provider "aws" {
  region = "${var.aws_region}"
}

data "terraform_remote_state" "infra_vpc" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.stackname}/infra-vpc.tfstate}"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "infra_networking" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.stackname}/infra-networking.tfstate}"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "infra_security_groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.stackname}/infra-security-groups.tfstate}"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "infra_internal_dns_zone" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.stackname}/infra-internal-dns-zone.tfstate}"
    region = "eu-west-1"
  }
}

resource "aws_elb" "monitoring_elb" {
  name            = "${var.stackname}-monitoring"
  subnets         = ["${data.terraform_remote_state.infra_networking.public_subnet_ids}"]
  security_groups = ["${data.terraform_remote_state.infra_security_groups.sg_monitoring_elb_id}"]
  internal        = "false"

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3

    target   = "TCP:443"
    interval = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = "${map("Name", "${var.stackname}-monitoring", "Project", var.stackname, "aws_migration", "monitoring")}"
}

# TODO: Add external record when we have the external zones working

module "monitoring" {
  source                               = "../../modules/aws/node_group"
  name                                 = "${var.stackname}-monitoring"
  vpc_id                               = "${data.terraform_remote_state.infra_vpc.vpc_id}"
  default_tags                         = "${map("Project", var.stackname, "aws_stackname", var.stackname, "aws_migration", "monitoring", "aws_hostname", "monitoring-1")}"
  instance_subnet_ids                  = "${data.terraform_remote_state.infra_networking.private_subnet_ids}"
  instance_security_group_ids          = ["${data.terraform_remote_state.infra_security_groups.sg_monitoring_id}", "${data.terraform_remote_state.infra_security_groups.sg_management_id}"]
  instance_type                        = "t2.medium"
  create_instance_key                  = true
  instance_key_name                    = "${var.stackname}-monitoring"
  instance_public_key                  = "${var.ssh_public_key}"
  instance_additional_user_data_script = "${file("${path.module}/additional_user_data.txt")}"
  instance_elb_ids                     = ["${aws_elb.monitoring_elb.id}"]
}

# Outputs
# --------------------------------------------------------------

output "monitoring_elb_dns_name" {
  value       = "${aws_elb.monitoring_elb.dns_name}"
  description = "DNS name to access the monitoring service"
}
