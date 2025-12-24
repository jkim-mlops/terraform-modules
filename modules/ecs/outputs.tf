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
