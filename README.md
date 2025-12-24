# terraform-modules
Custom modules to simplify terraform deployments.

## Usage
Reference the modules as shown in the example below. For more details please view the docs for each individual module.

## Example

```hcl
module "submodule" {
    // please remember to version constrain this module with `?ref=<your version>`
    source = "git@github.com:jkim-mlops/terraform-modules.git//modules/submodule"

    // ...
}
```
