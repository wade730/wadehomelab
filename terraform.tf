terraform {
  required_version = "1.7.5" # declares required terraform version
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0" # declares required version of the aws provider 
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "chummbucket"
    key            = "terraform-state"
    dynamodb_table = "terraform-state-lock-dynamo"
    encrypt        = true
    region         = "us-east-1"
  }
}