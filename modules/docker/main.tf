locals {
  full_ref = "${var.image_name}:${var.image_tag}"
}

resource "aws_ecr_repository" "this" {
  name                 = var.image_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "docker_image" "this" {
  name = local.full_ref
  build {
    context  = var.build_context
    tag      = ["${aws_ecr_repository.this.repository_url}:${var.image_tag}"]
    platform = "linux/amd64"
  }
  triggers = {
    build_sha = sha1(join("", [for f in fileset(var.build_context, "**") : sha1(file("${var.build_context}/${f}"))]))
  }
}

resource "docker_registry_image" "this" {
  name          = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
  keep_remotely = true
  depends_on    = [docker_image.this]

  triggers = {
    build_sha = docker_image.this.repo_digest
  }
}