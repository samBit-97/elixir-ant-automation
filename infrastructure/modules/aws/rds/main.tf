resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_db_instance" "this" {
  identifier              = var.name
  db_name                 = var.db_name
  allocated_storage       = var.allocated_storage
  engine                  = "postgres"
  engine_version          = "15.13"
  instance_class          = var.instance_class
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = var.vpc_security_group_ids
  skip_final_snapshot     = true
  publicly_accessible     = var.publicly_accessible
  backup_retention_period = 0
  tags                    = var.tags
}
