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

resource "aws_sqs_queue" "jobs" {
  name                       = "${var.project}-${var.env}-jobs"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30

  tags = {
    Name        = "Jobs Queue"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic" "notifications" {
  name = "${var.project}-${var.env}-notifications"

  tags = {
    Name        = "Notifications"
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.demo.arn
}

output "jobs_queue_url" {
  value = aws_sqs_queue.jobs.url
}

output "sns_topic_arn" {
  value = aws_sns_topic.notifications.arn
}
