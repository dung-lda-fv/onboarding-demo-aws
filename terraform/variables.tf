variable "docker_image" {
  description = "Docker image để deploy"
  default     = "my-app:latest"
}

variable "env" {
  description = "Environment"
  default     = "dev"
}