
resource "aws_instance" "bastion_server" {
  ami                         = data.aws_ami.tomcat_server_image.id
  associate_public_ip_address = true
  key_name                    = "Big_data_hadoop"
  subnet_id                   = aws_subnet.public_subnet.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.bastion_server_security.id]

  tags = {
    Name = "bastion server"
  }
  depends_on = [aws_security_group.bastion_server_security]
}

resource "aws_security_group" "bastion_server_security" {
  name        = "bastion_server_security"
  description = "allow connection to bastion server for managing the infrastructure"
  vpc_id      = aws_vpc.Webapp.id

  tags = {
    name = "bastion_server_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allows_ssh" {
  security_group_id = aws_security_group.bastion_server_security.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"


}

resource "aws_vpc_security_group_egress_rule" "basition_server_egress" {
  security_group_id = aws_security_group.bastion_server_security.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}


resource "aws_instance" "servers" {
  for_each = {
    server_1 = aws_subnet.private_subnet_1.id,
    server_2 = aws_subnet.private_subnet_2.id
  }
  ami                    = data.aws_ami.tomcat_server_image.id
  instance_type          = "t2.micro"
  key_name               = "Big_data_hadoop"
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.tomcat_server.id]

  tags = {
    Name   = "Tomacat server",
    Server = each.key
  }

  user_data = file("./setup.sh") //script running


}

resource "aws_security_group" "tomcat_server" {
  name        = "allow ssh"
  description = "allow ssh connection from bastion server"
  vpc_id      = aws_vpc.Webapp.id
  tags = {
    Name = "allow ssh to bastion server"
  }

}

resource "aws_vpc_security_group_ingress_rule" "server_ssh" {
  security_group_id = aws_security_group.tomcat_server.id
  cidr_ipv4         = aws_vpc.Webapp.cidr_block
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "server_ssh_1" {
  security_group_id = aws_security_group.tomcat_server.id
  cidr_ipv4         = aws_vpc.Webapp.cidr_block
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}



resource "aws_vpc_security_group_egress_rule" "server_egress" {
  security_group_id = aws_security_group.tomcat_server.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "server_load_balancer" {
  name               = "server-lb"
  internal           = false
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.lb_security_group.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
  load_balancer_type = "application"
  tags = {
    Name = "server_load_balancer"
  }

}

resource "aws_lb_listener" "server_lb_lister" {
  load_balancer_arn = aws_lb.server_load_balancer.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server_lb_target_group.arn
  }

}

resource "aws_lb_target_group" "server_lb_target_group" {
  load_balancing_algorithm_type = "round_robin"
  name                          = "server-lb"
  port                          = 8080
  protocol                      = "HTTP"
  vpc_id                        = aws_vpc.Webapp.id

}

resource "aws_lb_target_group_attachment" "server_id" {
  for_each         = aws_instance.servers
  target_group_arn = aws_lb_target_group.server_lb_target_group.id
  target_id        = each.value.id
  port             = 8080

}

resource "aws_security_group" "lb_security_group" {
  name        = "lb_security_group"
  description = "Allow inbound traffic to the load balancer"
  vpc_id      = aws_vpc.Webapp.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_security_group"
  }
}

resource "aws_db_subnet_group" "database_subnets" {
  name       = "database_subnet"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name        = "mysql_subnet_group"
    Description = "subnet group for mysqldatabase"
  }

}

resource "aws_db_instance" "primary_database" {
  allocated_storage           = 20
  allow_major_version_upgrade = true
  copy_tags_to_snapshot       = true
  db_name                     = "primarydatabase"
  db_subnet_group_name        = aws_db_subnet_group.database_subnets.name
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  network_type                = "IPV4"
  username                    = "root"
  password                    = "12345678"
  identifier                  = "ewa-primary-db"
  license_model               = "general-public-license"
  vpc_security_group_ids      = [aws_security_group.db_instance.id]
  parameter_group_name        = "default.mysql8.0"
  skip_final_snapshot         = true
  backup_retention_period     = 7  

  tags = {
    Name = "primary-db"
  }
}

resource "aws_db_instance" "replica_database" {
  instance_class              = "db.t3.micro"
  identifier                  = "ewa-replica-db"
  vpc_security_group_ids      = [aws_security_group.db_instance.id]
  replicate_source_db         = aws_db_instance.primary_database.identifier

  depends_on = [ aws_db_instance.primary_database ]
  tags = {
    Name = "replica-db"
  }

}



resource "aws_security_group" "db_instance" {
  name   = "sql-database"
  vpc_id = aws_vpc.Webapp.id
  tags = {
    "Name" = "sql_database"
  }

}

resource "aws_vpc_security_group_ingress_rule" "db_ingress" {
  security_group_id = aws_security_group.db_instance.id
  cidr_ipv4         = "10.0.0.0/16"
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db_instance.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = -1
}

resource "aws_vpc_security_group_ingress_rule" "db_ssh" {
  security_group_id = aws_security_group.db_instance.id

  cidr_ipv4   = "10.0.0.0/16"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}









