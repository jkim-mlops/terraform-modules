<!-- BEGIN_TF_DOCS -->
# docker

Build Docker containers locally and push to ECR.

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [docker_image.this](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_registry_image.this](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build_context"></a> [build\_context](#input\_build\_context) | The build context for building the Docker image. | `string` | n/a | yes |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | The name of the Docker image to pull or build. | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The tag of the Docker image to pull or build. | `string` | n/a | yes |
| <a name="input_platform"></a> [platform](#input\_platform) | The target platform for the Docker image build (e.g., linux/amd64, linux/arm64). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ecr_repo"></a> [ecr\_repo](#output\_ecr\_repo) | The AWS ECR repository. |
| <a name="output_image"></a> [image](#output\_image) | The Docker image. |
| <a name="output_image_name"></a> [image\_name](#output\_image\_name) | The Docker image name. |
| <a name="output_image_tag"></a> [image\_tag](#output\_image\_tag) | The Docker image tag. |
<!-- END_TF_DOCS -->