data "aws_rds_engine_version" "postgres" {
  engine                 = "postgres"
  parameter_group_family = "postgres16"
  version                = "16"
  latest                 = true
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.project}-db"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = merge(local.tags, {
    Name = "${local.project}-db"
  })
}

resource "aws_db_instance" "main" {
  identifier        = "${local.project}-postgres"
  engine            = "postgres"
  engine_version    = data.aws_rds_engine_version.postgres.version_actual
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = local.db_name
  username = local.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = merge(local.tags, {
    Name = "${local.project}-postgres"
  })
}
