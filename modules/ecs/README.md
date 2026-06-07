<!-- BEGIN_TF_DOCS -->
# ecs

ECS cluster setup with auto-scaling via Capacity Providers.

## Example

```hcl
/**
 * # ecs/example
 *
 * Example usage of the ECS module with VPC, Docker, and SQS integration.
 */

module "ecs" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/ecs"

  name            = var.name
  cidr_blocks     = [module.vpc.vpc_cidr_block]
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  architecture    = "arm64"
  instance_type   = "m6g.large"
  logging_enabled = true
  aws_region      = var.aws_region
  tasks = {
    "${module.docker.image_name}" = {
      container_definition = {
        name      = module.docker.image_name
        image     = "${module.docker.ecr_repo.repository_url}:${module.docker.image_tag}"
        cpu       = 1024 * 2
        memory    = 1048 * 4
        essential = true
        environment = [
          {
            name  = "SQS_QUEUE_URL"
            value = module.sqs.queue.id
          },
          {
            name  = "LOGURU_LEVEL"
            value = "INFO"
          }
        ]
      }
      iam = {
        sqsPermissions = {
          actions = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage"
          ]
          resources = [
            module.sqs.queue.arn,
            module.sqs.dlq.arn
          ]
        }
      }
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | CPU architecture for ECS container instances (x86\_64 or arm64). Must align with instance\_type. | `string` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP to Fargate tasks (only valid for public subnets). | `bool` | `false` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | n/a | yes |
| <a name="input_cidr_blocks"></a> [cidr\_blocks](#input\_cidr\_blocks) | List of CIDR blocks for security group ingress rules | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | Desired number of instances in the ECS Auto Scaling Group. | `number` | `0` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for the ECS capacity provider's launch template | `string` | n/a | yes |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | ECS launch type: EC2 or FARGATE. Controls task definition compatibility. | `string` | `"FARGATE"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days | `number` | n/a | yes |
| <a name="input_logging_enabled"></a> [logging\_enabled](#input\_logging\_enabled) | Enable CloudWatch logging for tasks | `bool` | n/a | yes |
| <a name="input_managed_instances"></a> [managed\_instances](#input\_managed\_instances) | Managed Instances capacity provider config. When non-null, creates an MI capacity provider; null disables it. | <pre>object({<br/>    instance_requirements = object({<br/>      vcpu_count              = object({ min = number, max = optional(number) })<br/>      memory_mib              = object({ min = number, max = optional(number) })<br/>      cpu_manufacturers       = optional(list(string)) # e.g. ["amazon-web-services"] for Graviton<br/>      allowed_instance_types  = optional(list(string)) # pin specific types if desired<br/>      excluded_instance_types = optional(list(string))<br/>      burstable_performance   = optional(string)       # "included" | "excluded" | "required"<br/>      instance_generations    = optional(list(string)) # e.g. ["current"]<br/>    })<br/>    scale_in_after_seconds = optional(number) # warm-reuse delay; 0 = scale to zero immediately<br/>    storage_size_gib       = optional(number) # root volume for DinD scratch<br/>    monitoring             = optional(string) # "BASIC" | "DETAILED"<br/>    propagate_tags         = optional(bool, true)<br/>  })</pre> | `null` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances in the ECS Auto Scaling Group. | `number` | `1` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances in the ECS Auto Scaling Group. | `number` | `0` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the ECS cluster | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs for the ECS service. | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the ECS service network configuration. | `list(string)` | n/a | yes |
| <a name="input_tasks"></a> [tasks](#input\_tasks) | Container definitions for the ECS task | <pre>map(object({<br/>    container_definition = object({<br/>      name      = string<br/>      image     = string<br/>      cpu       = number<br/>      memory    = number<br/>      essential = bool<br/>      environment = optional(list(object({<br/>        name  = string<br/>        value = string<br/>      })))<br/>      portMappings = optional(list(object({<br/>        containerPort = number<br/>        hostPort      = number<br/>        protocol      = string<br/>      })))<br/>    })<br/>    iam = optional(map(object({<br/>      actions   = list(string)<br/>      resources = list(string)<br/>    })), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the ECS service will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | ECS cluster resource (full object). |
| <a name="output_managed_instances_capacity_provider"></a> [managed\_instances\_capacity\_provider](#output\_managed\_instances\_capacity\_provider) | Name of the Managed Instances capacity provider, or null when disabled. |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | The security group used by the ECS service. |
| <a name="output_service"></a> [service](#output\_service) | ECS service resource(s) (full object map when using for\_each). |
| <a name="output_task_definitions"></a> [task\_definitions](#output\_task\_definitions) | Map of ECS task definitions by task name |
| <a name="output_task_execution_role"></a> [task\_execution\_role](#output\_task\_execution\_role) | ARN of the ECS task execution role |
| <a name="output_task_roles"></a> [task\_roles](#output\_task\_roles) | Map of ECS task roles by task name |

## Modules

No modules.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.27.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.27.0 |
<!-- END_TF_DOCS -->