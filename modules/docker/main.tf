/**
 * # docker
 *
 * Build Docker containers locally and push to ECR. 
 */


locals {
  full_ref = "${var.image_name}:${var.image_tag}"

  excluded_dirs = ["__pycache__", ".pytest_cache", ".ruff_cache", ".mypy_cache"]

  # Files matching any caller-supplied glob are dropped from the build hash so
  # edits to them (e.g. tests) don't trigger a rebuild.
  excluded_by_pattern = toset(flatten([
    for pattern in var.build_hash_excludes : fileset(var.build_context, pattern)
  ]))

  hashed_files = [
    for f in fileset(var.build_context, "**") :
    filesha256("${var.build_context}/${f}")
    if !anytrue([
      for d in local.excluded_dirs :
      startswith(f, "${d}/") || strcontains(f, "/${d}/")
    ]) && !contains(local.excluded_by_pattern, f)
  ]

  build_sha = sha1(join("", local.hashed_files))
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
    context    = var.build_context
    tag        = ["${aws_ecr_repository.this.repository_url}:${var.image_tag}"]
    platform   = var.platform
    build_args = var.build_args
  }
  triggers = {
    build_sha  = local.build_sha
    build_args = jsonencode(var.build_args)
  }
}

resource "docker_registry_image" "this" {
  name          = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
  keep_remotely = true
  depends_on    = [docker_image.this]

  triggers = {
    build_sha = local.build_sha
  }
}