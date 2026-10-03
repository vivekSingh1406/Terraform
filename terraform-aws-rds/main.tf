data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_vpc" "database" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.identifier}-vpc" }
}

# RDS requires subnets in at least two availability zones, even for Single-AZ.
resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.database.id
  cidr_block        = cidrsubnet(aws_vpc.database.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "${var.identifier}-subnet-${count.index + 1}" }
}

resource "aws_internet_gateway" "database" {
  count  = var.publicly_accessible ? 1 : 0
  vpc_id = aws_vpc.database.id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.database.id
  tags   = { Name = "${var.identifier}-routes" }
}

resource "aws_route" "internet" {
  count                  = var.publicly_accessible ? 1 : 0
  route_table_id         = aws_route_table.database.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.database[0].id
}

resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Attach this group to application EC2 instances in this VPC to permit DB access.
resource "aws_security_group" "client" {
  name_prefix = "${var.identifier}-client-"
  description = "Attach to applications that need MySQL access"
  vpc_id      = aws_vpc.database.id
}

resource "aws_security_group" "database" {
  name_prefix = "${var.identifier}-db-"
  description = "MySQL access from approved clients only"
  vpc_id      = aws_vpc.database.id
}

resource "aws_vpc_security_group_egress_rule" "client" {
  security_group_id            = aws_security_group.client.id
  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "application" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.client.id
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "client_cidr" {
  for_each          = var.allowed_client_cidrs
  security_group_id = aws_security_group.database.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.identifier}-subnets"
  subnet_ids = aws_subnet.database[*].id
}

resource "aws_db_parameter_group" "mysql" {
  name_prefix = "${var.identifier}-"
  family      = "mysql8.4"
  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "mysql" {
  identifier                  = var.identifier
  engine                      = "mysql"
  engine_version              = "8.4"
  engine_lifecycle_support    = "open-source-rds-extended-support-disabled"
  instance_class              = var.instance_class
  db_name                     = var.database_name
  username                    = "dbadmin"
  manage_master_user_password = true

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  port                   = 3306
  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.mysql.name
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  backup_retention_period    = 7
  backup_window              = "19:00-20:00"
  maintenance_window         = "sun:21:00-sun:22:00"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : coalesce(var.final_snapshot_identifier, "${var.identifier}-final")

  # Public connectivity must be ready before RDS is provisioned.
  depends_on = [aws_route.internet, aws_route_table_association.database]

  lifecycle {
    precondition {
      condition     = !var.publicly_accessible || length(var.allowed_client_cidrs) > 0
      error_message = "Public access requires at least one explicitly allowed client CIDR (prefer your public IP/32)."
    }
  }
}
