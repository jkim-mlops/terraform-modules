module "docker" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/docker"

  image_name    = "sqs-polling"
  image_tag     = "0.3.0"
  build_context = "./images/sqs-polling"
}