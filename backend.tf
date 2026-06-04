terraform {
  backend "s3" {
    bucket         = "tf-state-iac-orchestration-example"
    key            = "terraform/state"
    region         = "us-east-1"
    dynamodb_table = "tf-lock-iac-orchestration-example"
    encrypt        = true
  }
}
