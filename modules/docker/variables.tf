variable "image_name" {
  description = "The name of the Docker image to pull or build."
  type        = string

}

variable "image_tag" {
  description = "The tag of the Docker image to pull or build."
  type        = string
}

variable "build_context" {
  description = "The build context for building the Docker image."
  type        = string
}
