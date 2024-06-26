output "s3_bucket_arn" {
  value       = aws_s3_bucket.chummbucket.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform-state-lock-dynamo.name
  description = "The Name of the Dynamo DB table"
}
