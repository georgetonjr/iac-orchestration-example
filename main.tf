terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  default = "us-east-1"
}

variable "env" {
  default = "dev"
}

variable "project" {
  default = "iac-orchestration-example"
}

# Recurso de demo: bucket S3
resource "aws_s3_bucket" "demo" {
  bucket = "demo-digger-iac-${var.env}-${random_id.suffix.hex}"

  tags = {
    Name        = "Digger Demo"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.demo.arn
}
