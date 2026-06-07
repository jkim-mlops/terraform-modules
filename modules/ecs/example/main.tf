/**
 * # ecs/example
 *
 * Example usage of the ECS module: a default FARGATE worker (with SQS access)
 * alongside a privileged Docker-in-Docker build runner on an ECS Managed
 * Instances capacity provider sized for ARM64 / Graviton.
 */

module "ecs" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/ecs"

  name            = var.name
  cidr_blocks     = [module.vpc.vpc_cidr_block]
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  architecture    = "arm64"
  instance_type   = "m6g.large" # used by the ASG path only; MI selects via instance_requirements
  launch_type     = "FARGATE"   # default capacity provider for non-MI tasks
  logging_enabled = true
  aws_region      = var.aws_region

  # Presence of this object creates the Managed Instances capacity provider.
  managed_instances = {
    instance_requirements = {
      vcpu_count            = { min = 2, max = 8 }
      memory_mib            = { min = 4096 }          # >= 4 GiB
      cpu_manufacturers     = ["amazon-web-services"] # Graviton / ARM64
      instance_generations  = ["current"]
      burstable_performance = "excluded" # steady CPU for builds
    }
    storage_size_gib       = 100     # room for Docker image layers
    scale_in_after_seconds = 0       # scale to zero when idle (raise to keep instances warm)
    monitoring             = "BASIC" # or "DETAILED"
  }

  tasks = {
    # Default FARGATE worker.
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

    # Privileged Docker-in-Docker runner on Managed Instances.
    dind = {
      requires_compatibilities = ["MANAGED_INSTANCES"]
      container_definition = {
        name       = "dind"
        image      = "${module.docker.ecr_repo.repository_url}:${module.docker.image_tag}"
        cpu        = 1024 * 2
        memory     = 1048 * 4
        essential  = true
        privileged = true # required for Docker-in-Docker
        linuxParameters = {
          capabilities = { add = ["SYS_ADMIN", "NET_ADMIN"] }
        }
      }
    }
  }
}