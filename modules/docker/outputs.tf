output "image" {
  description = "The Docker image."
  value       = docker_registry_image.this
}

output "ecr_repo" {
  description = "The AWS ECR repository."
  value       = aws_ecr_repository.this
}

output "image_name" {
  description = "The Docker image name."
  value       = var.image_name
}

output "image_tag" {
  description = "The Docker image tag."
  value       = var.image_tag
}
