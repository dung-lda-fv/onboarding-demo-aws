variable "env" {
  description = "Environment"
  default     = "dev"
}

variable "image_tag" {
  description = "Docker image tag được build từ CI (GITHUB_SHA)"
  default     = "latest"
}