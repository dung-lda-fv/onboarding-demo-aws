variable "env" {
  description = "Environment"
  default     = "dev"
}

variable "image_tag" {
  description = "Docker image tag được build từ CI (GITHUB_SHA)"
  default     = "latest"
}

variable "local_registry" {
  description = "Local Docker registry URL (thay thế ECR cho LocalStack CE)"
  default     = "localhost:5000"
}