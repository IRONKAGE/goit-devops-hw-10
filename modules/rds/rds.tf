resource "aws_db_parameter_group" "rds_pg" {
  count       = var.use_aurora ? 0 : 1
  name_prefix = "${local.name_prefix}-rds-pg-"
  family      = var.db_parameter_group_family

  parameter {
    name  = "max_connections"
    value = "100"
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "work_mem"
    value = "4096"
  }

  tags = local.common_tags
}

resource "aws_db_instance" "rds" {
  count                  = var.use_aurora ? 0 : 1
  identifier             = "${local.name_prefix}-rds"
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = 20

  username               = "adminuser"
  password               = random_password.db_master_pass.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  parameter_group_name   = aws_db_parameter_group.rds_pg[0].name

  multi_az               = var.multi_az
  skip_final_snapshot    = true

  tags = local.common_tags
}
