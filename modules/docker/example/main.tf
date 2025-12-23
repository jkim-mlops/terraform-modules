module "docker" {
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/docker?ref=0.1.0"

  image_name    = "sqs-polling"
  image_tag     = "0.3.0"
  build_context = "./images/sqs-polling"
}