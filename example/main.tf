module "submodule" {
  // please remember to version constrain this module with `?ref=<your version>`
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/submodule"

  // ...
}