terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Endpoint URL có thể override qua biến môi trường TF_VAR_localstack_endpoint
# - Khi chạy trong docker network  → http://localstack:4566
# - Khi chạy trên host (CI runner) → http://localhost:4566
variable "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  default     = "http://localhost:4566"
}

provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  endpoints {
    ecr            = var.localstack_endpoint
    ecs            = var.localstack_endpoint
    ec2            = var.localstack_endpoint
    iam            = var.localstack_endpoint
    sts            = var.localstack_endpoint
    cloudwatch     = var.localstack_endpoint
    cloudwatchlogs = var.localstack_endpoint
  }

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}
