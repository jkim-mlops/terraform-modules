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

variable "platform" {
  description = "The target platform for the Docker image build (e.g., linux/amd64, linux/arm64)."
  type        = string
}

variable "build_args" {
  description = "Build-time ARGs passed to the docker build."
  type        = map(string)
  default     = {}
}
