output "state_bucket_name" {
  description = "Назва створеного S3 бакета"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "Назва створеної DynamoDB таблиці"
  value       = aws_dynamodb_table.terraform_locks.name
}
