## Project: app-puppetmaster

Puppetmaster node


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws_environment | AWS environment | string | - | yes |
| aws_region | AWS region | string | `eu-west-1` | no |
| elb_internal_certname | The ACM cert domain name to find the ARN of | string | - | yes |
| enable_bootstrap | Whether to create the ELB which allows a user to SSH to the Puppetmaster from the office | string | `false` | no |
| instance_ami_filter_name | Name to use to find AMI images | string | `` | no |
| puppetmaster_instance_type | Instance type for the mirrorer instance | string | `m5.xlarge` | no |
| remote_state_bucket | S3 bucket we store our terraform state in | string | - | yes |
| remote_state_infra_monitoring_key_stack | Override stackname path to infra_monitoring remote state | string | `` | no |
| remote_state_infra_networking_key_stack | Override infra_networking remote state path | string | `` | no |
| remote_state_infra_root_dns_zones_key_stack | Override stackname path to infra_root_dns_zones remote state | string | `` | no |
| remote_state_infra_security_groups_key_stack | Override infra_security_groups stackname path to infra_vpc remote state | string | `` | no |
| remote_state_infra_stack_dns_zones_key_stack | Override stackname path to infra_stack_dns_zones remote state | string | `` | no |
| remote_state_infra_vpc_key_stack | Override infra_vpc remote state path | string | `` | no |
| stackname | Stackname | string | - | yes |
| user_data_snippets | List of user-data snippets | list | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| puppetdb_service_dns_name | DNS name to access the node service |
| puppetmaster_bootstrap_elb_dns_name | DNS name to access the puppetmaster bootstrap service |
| puppetmaster_internal_elb_dns_name | DNS name to access the puppetmaster service |
| service_dns_name | DNS name to access the node service |

