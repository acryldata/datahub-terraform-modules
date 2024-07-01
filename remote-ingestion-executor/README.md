<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | 5.4.0 |
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | 5.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI | `bool` | `true` | no |
| <a name="input_cluster_configuration"></a> [cluster\_configuration](#input\_cluster\_configuration) | The execute command configuration for the cluster | `any` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster (up to 255 letters, numbers, hyphens, and underscores) | `string` | `""` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Number of cpu units used by the task | `number` | `1024` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a log group is created by this module. If not, AWS will automatically create one if logging is enabled | `bool` | `true` | no |
| <a name="input_create_task_exec_iam_role"></a> [create\_task\_exec\_iam\_role](#input\_create\_task\_exec\_iam\_role) | Determines whether the ECS task definition IAM role should be created | `bool` | `false` | no |
| <a name="input_create_task_exec_policy"></a> [create\_task\_exec\_policy](#input\_create\_task\_exec\_policy) | Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters | `bool` | `true` | no |
| <a name="input_create_tasks_iam_role"></a> [create\_tasks\_iam\_role](#input\_create\_tasks\_iam\_role) | Determines whether the ECS tasks IAM role should be created | `bool` | `true` | no |
| <a name="input_datahub"></a> [datahub](#input\_datahub) | Acryl Executor configuration | <pre>object({<br>    # The container image<br>    image     = optional(string, "795586375822.dkr.ecr.us-west-2.amazonaws.com/acryl-sqs-remote-executor")<br>    image_tag = optional(string, "v0.0.4.2")<br>    # Acryl DataHub URL: The URL for your DataHub instance, e.g. <your-company>.acryl.io/gms<br>    url = string<br>    # Unique Executor Id. Warning - do not change this without consulting with your Acryl rep<br>    executor_id = optional(string, "remote")<br>    # SQS Queue ARN<br>    queue_url = string<br>    # SQS Queue aws region<br>    aws_region = optional(string, data.aws_region.current.name)<br>  })</pre> | n/a | yes |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_enable_cloudwatch_logging"></a> [enable\_cloudwatch\_logging](#input\_enable\_cloudwatch\_logging) | Determines whether CloudWatch logging is configured for the container definition | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Specifies whether to enable Amazon ECS Exec for the tasks within the service | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment variables to pass to the container | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_log_configuration"></a> [log\_configuration](#input\_log\_configuration) | The log configuration for the container | `any` | `{}` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount (in MiB) of memory used by the task | `number` | `2048` | no |
| <a name="input_network_mode"></a> [network\_mode](#input\_network\_mode) | Docker networking mode to use for the containers in the task | `string` | `"awsvpc"` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task | `list(string)` | <pre>[<br>  "EC2",<br>  "FARGATE"<br>]</pre> | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | The secrets to pass to the container. For more information, see [Specifying Sensitive Data](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html) in the Amazon Elastic Container Service Developer Guide | <pre>list(object({<br>    name      = string<br>    valueFrom = string<br>  }))</pre> | `[]` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security groups to associate with the task | `list(string)` | `[]` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Security group rules to add to the security group created | `any` | `{}` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of the service (up to 255 letters, numbers, hyphens, and underscores) | `string` | `"dh-sqs-remote-executor"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnets to associate with the task | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#input\_task\_exec\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_task_exec_iam_role_policies"></a> [task\_exec\_iam\_role\_policies](#input\_task\_exec\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_task_exec_secret_arns"></a> [task\_exec\_secret\_arns](#input\_task\_exec\_secret\_arns) | List of SecretsManager secret ARNs the task execution role will be permitted to get/read | `list(string)` | `[]` | no |
| <a name="input_task_exec_ssm_param_arns"></a> [task\_exec\_ssm\_param\_arns](#input\_task\_exec\_ssm\_param\_arns) | List of SSM parameter ARNs the task execution role will be permitted to get/read | `list(string)` | `[]` | no |
| <a name="input_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#input\_tasks\_iam\_role\_arn) | Existing IAM role ARN | `string` | `null` | no |
| <a name="input_tasks_iam_role_name"></a> [tasks\_iam\_role\_name](#input\_tasks\_iam\_role\_name) | Name to use on IAM role created | `string` | `null` | no |
| <a name="input_tasks_iam_role_policies"></a> [tasks\_iam\_role\_policies](#input\_tasks\_iam\_role\_policies) | Map of IAM role policy ARNs to attach to the IAM role | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->