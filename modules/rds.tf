
# Subnet group 

resource "aws_db_subnet_group" "db_subnet" {
  name       = "wp-db-subnet"
  subnet_ids = [for s in aws_subnet.private : s.id]
  tags = {
    Name = "wp-db-subnet-group"
  }
}

# Instance 

resource "aws_db_instance" "rds" {
  
  identifier              = "wordpress-db"
  engine                  = "mysql"
  instance_class          = var.instance_class
  allocated_storage       = 20
  db_name                 = "wordpress"
  username                = "admin"
  password                = var.db_password
  multi_az                = var.multi_az
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
}

