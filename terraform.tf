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

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name           = "terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}