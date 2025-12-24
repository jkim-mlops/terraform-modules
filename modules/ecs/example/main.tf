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