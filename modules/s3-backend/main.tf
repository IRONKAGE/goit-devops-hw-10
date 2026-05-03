locals {
  # Формуємо унікальні назви на основі проекту та середовища
  bucket_name = "${var.project_name}-${var.environment}-terraform-state"
  table_name  = "${var.project_name}-${var.environment}-terraform-locks"
}

# 1. S3 Bucket для збереження стейту Terraform
resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.bucket_name
  force_destroy = true # Дозволяє видалити бакет при make destroy

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
  }
}

# 2. Увімкнення версіонування (щоб мати бекапи попередніх стейтів)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. DynamoDB таблиця для блокування стейту (захист від одночасного запуску)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = local.table_name
    Environment = var.environment
  }
}
