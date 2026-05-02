resource "aws_rds_cluster" "django_aurora_v2" {
  count                   = var.environment == "prod" ? 1 : 0

  # Динамічні імена для підтримки кількох середовищ (dev/prod)
  cluster_identifier      = "${local.name_prefix}-django-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned" # Обов'язково для Serverless v2
  engine_version          = var.engine_version # Використовуємо змінну!
  database_name           = "django_db"
  master_username         = "dbadmin"

  # Автоматичне управління паролем через AWS Secrets Manager
  manage_master_user_password = true

  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name

  # Якщо це prod, робимо снапшот. Якщо ні - дозволяємо швидке видалення
  skip_final_snapshot     = var.environment == "prod" ? false : true

  # Оптимізовані ліміти для Serverless v2 (0.5 ACU = 1GB RAM, 4.0 ACU = 8GB RAM)
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "django_aurora_instances" {
  # Створюємо 2 інстанси (Writer + 1 Reader) для Multi-AZ High Availability
  count               = var.environment == "prod" ? 2 : 0

  identifier          = "${local.name_prefix}-aurora-instance-${count.index}"

  # Звертаємось до кластера через індекс [0], оскільки додали count
  cluster_identifier  = aws_rds_cluster.django_aurora_v2[0].id

  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.django_aurora_v2[0].engine
  engine_version      = aws_rds_cluster.django_aurora_v2[0].engine_version

  tags = local.common_tags
}
