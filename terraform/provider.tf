terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"

  # Trỏ toàn bộ endpoint về LocalStack
  # Dùng tên service "localstack" vì cùng docker network
  endpoints {
    ec2 = "http://localstack:4566"
    s3 = "http://localstack:4566"
    iam = "http://localstack:4566"
    sts = "http://localstack:4566"
  }

  # Bắt buộc khi dùng LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}