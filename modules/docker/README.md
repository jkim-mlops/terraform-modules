<!-- BEGIN_TF_DOCS -->
# docker

Build Docker containers locally and push to ECR.

## Example

```hcl
module "docker" {
  source = "git@github.com:jkim-mlops/terraform-modules.git//modules/docker?ref=0.1.0"

  image_name    = "sqs-polling"
  image_tag     = "0.3.0"
  build_context = "./images/sqs-polling"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build_context"></a> [build\_context](#input\_build\_context) | The build context for building the Docker image. | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | The name of the Docker image to pull or build. | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The tag of the Docker image to pull or build. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repo"></a> [ecr\_repo](#output\_ecr\_repo) | The AWS ECR repository. |
| <a name="output_image"></a> [image](#output\_image) | The Docker image. |
| <a name="output_image_name"></a> [image\_name](#output\_image\_name) | The Docker image name. |
| <a name="output_image_tag"></a> [image\_tag](#output\_image\_tag) | The Docker image tag. |

## Modules

No modules.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.27.0 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | ~> 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.27.0 |
| <a name="provider_docker"></a> [docker](#provider\_docker) | ~> 3.6.2 |
<!-- END_TF_DOCS -->