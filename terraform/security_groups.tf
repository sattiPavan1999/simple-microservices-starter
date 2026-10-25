# ---------------- Load balancer (public entry point) ----------------
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Public load balancer"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------- Frontend ----------------
resource "aws_security_group" "frontend" {
  name        = "${local.name}-frontend-sg"
  description = "Frontend service"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name}-frontend-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_from_alb" {
  security_group_id            = aws_security_group.frontend.id
  description                  = "Frontend port from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.frontend_port
  to_port                      = var.frontend_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "frontend_all" {
  security_group_id = aws_security_group.frontend.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------- Backend services (users, products) ----------------
resource "aws_security_group" "backend" {
  for_each = var.backend_services

  name        = "${local.name}-${each.key}-sg"
  description = "${each.key} service"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name}-${each.key}-sg" }
}

# The frontend calls the APIs from the *browser*, so the ALB must be able to reach the backends.
resource "aws_vpc_security_group_ingress_rule" "backend_from_alb" {
  for_each = var.backend_services

  security_group_id            = aws_security_group.backend[each.key].id
  description                  = "${each.key} port from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = each.value.port
  to_port                      = each.value.port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "backend_all" {
  for_each = var.backend_services

  security_group_id = aws_security_group.backend[each.key].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------- RDS (one SG per DB) ----------------
resource "aws_security_group" "rds" {
  for_each = var.backend_services

  name        = "${local.name}-${each.key}-rds-sg"
  description = "RDS for ${each.key} service"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${local.name}-${each.key}-rds-sg" }
}

# Only the owning backend service may talk to its database.
resource "aws_vpc_security_group_ingress_rule" "rds_from_backend" {
  for_each = var.backend_services

  security_group_id            = aws_security_group.rds[each.key].id
  description                  = "PostgreSQL from ${each.key} service only"
  referenced_security_group_id = aws_security_group.backend[each.key].id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
