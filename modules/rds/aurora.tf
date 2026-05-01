resource "aws_rds_cluster_parameter_group" "aurora_cluster_pg" {
  count       = var.use_aurora ? 1 : 0
  name_prefix = "${local.name_prefix}-aurora-cluster-pg-"
  family      = var.db_parameter_group_family

  parameter {
    name  = "log_statement"
    value = "all"
    apply_method = "immediate"
  }

  tags = local.common_tags
}

resource "aws_rds_cluster" "aurora" {
  count                           = var.use_aurora ? 1 : 0
  cluster_identifier              = "${local.name_prefix}-aurora"
  engine                          = var.engine
  engine_version                  = var.engine_version
  master_username                 = "adminuser"
  master_password                 = random_password.db_master_pass.result
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.db_sg.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_pg[0].name

  skip_final_snapshot             = true

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "aurora_writer" {
  count              = var.use_aurora ? 1 : 0
  identifier         = "${local.name_prefix}-aurora-writer"
  cluster_identifier = aws_rds_cluster.aurora[0].id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora[0].engine
  engine_version     = aws_rds_cluster.aurora[0].engine_version

  db_subnet_group_name = aws_db_subnet_group.this.name

  tags = local.common_tags
}
