# One RDS PostgreSQL instance per backend (mirrors docker-compose: users-db, products-db).
# The initial database (users_db / products_db) is created by RDS via db_name,
# so Prisma `migrate deploy` can run straight away.

resource "random_password" "db" {
  for_each = var.backend_services

  length  = 24
  special = false # keeps the password URL-safe for DATABASE_URL
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnets"
  subnet_ids = aws_subnet.db[*].id

  tags = { Name = "${local.name}-db-subnets" }
}

resource "aws_db_parameter_group" "postgres" {
  name_prefix = "${local.name}-pg${var.db_engine_major_version}-"
  family      = "postgres${var.db_engine_major_version}"
  description = "Parameters for ${local.name} PostgreSQL"

  parameter {
    name  = "rds.force_ssl"
    value = var.db_force_ssl ? "1" : "0"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  for_each = var.backend_services

  identifier = "${local.name}-${each.key}-db"

  engine         = "postgres"
  engine_version = var.db_engine_major_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = each.value.db_name
  username = var.db_username
  password = random_password.db[each.key].result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds[each.key].id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  backup_retention_period    = var.db_backup_retention_days
  auto_minor_version_upgrade = true
  apply_immediately          = true

  # Practice-friendly: easy to tear down. Change for anything real.
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = true

  lifecycle {
    # engine_version "16" resolves to e.g. 16.4; don't fight AWS minor upgrades
    ignore_changes = [engine_version]
  }
}

# Store the full DATABASE_URL in SSM Parameter Store (SecureString = free, encrypted).
# Your containers / Kubernetes can read these instead of hard-coding secrets in .env files.
resource "aws_ssm_parameter" "database_url" {
  for_each = var.backend_services

  name        = "/${local.name}/${each.key}/DATABASE_URL"
  description = "DATABASE_URL for ${each.key} service"
  type        = "SecureString"
  value = format(
    "postgresql://%s:%s@%s:%d/%s?schema=public",
    var.db_username,
    random_password.db[each.key].result,
    aws_db_instance.main[each.key].address,
    aws_db_instance.main[each.key].port,
    each.value.db_name
  )
}
