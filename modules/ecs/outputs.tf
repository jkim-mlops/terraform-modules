output "security_group" {
  description = "The security group used by the ECS service."
  value       = aws_security_group.this
}
output "task_execution_role" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.this
}

output "task_roles" {
  description = "Map of ECS task roles by task name"
  value       = aws_iam_role.task
}

output "cluster" {
  description = "ECS cluster resource (full object)."
  value       = aws_ecs_cluster.this
}

output "service" {
  description = "ECS service resource(s) (full object map when using for_each)."
  value       = aws_ecs_service.this
}

output "task_definitions" {
  description = "Map of ECS task definitions by task name"
  value       = aws_ecs_task_definition.this
}

output "managed_instances_capacity_provider" {
  description = "Name of the Managed Instances capacity provider, or null when disabled."
  value       = var.managed_instances != null ? aws_ecs_capacity_provider.mi[0].name : null
}
