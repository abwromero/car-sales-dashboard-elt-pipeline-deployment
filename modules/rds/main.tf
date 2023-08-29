module "rds_secrets" {
  source = "../secrets"
}

resource "aws_db_subnet_group" "rds_vpc_deployment" {
  name       = "${var.microservice_name}_rds_db_subnet_group"
  subnet_ids = var.rds_subnets_ids[*]

  tags = {
    Name = "${var.microservice_name}-db-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.microservice_name}_rds_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = var.rds_ingress_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.microservice_name}-db-security-group"
  }
}

resource "aws_db_instance" "db_deployment" {
  allocated_storage      = var.rds_allocated_storage
  apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.rds_vpc_deployment.id
  name                   = "${var.microservice_name}appdatabase"
  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  iops                   = var.rds_iops
  max_allocated_storage  = var.rds_max_allocated_storage
  publicly_accessible    = var.rds_public_access
  storage_encrypted      = true
  storage_type           = var.rds_storage_type
  multi_az               = true
  username               = module.rds_secrets.username
  password               = module.rds_secrets.password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.microservice_name}-db"
  }
}