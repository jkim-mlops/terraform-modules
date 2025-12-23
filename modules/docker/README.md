<!-- BEGIN_TF_DOCS -->


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
<!-- END_TF_DOCS -->