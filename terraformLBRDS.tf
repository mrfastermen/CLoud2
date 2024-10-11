# Crear un VPC
resource "aws_vpc" "cloud_vpc" {
  cidr_block = "30.0.0.0/16"

  enable_dns_support   = true  
  enable_dns_hostnames = true  

  tags = {
    Name = "cloud-vpc"
  }
}

# Crear dos subredes públicas y privadas para las instancias EC2 y el ALB
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.cloud_vpc.id
  cidr_block        = "30.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.cloud_vpc.id
  cidr_block        = "30.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.cloud_vpc.id
  cidr_block        = "30.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.cloud_vpc.id
  cidr_block        = "30.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Crear un Internet Gateway para permitir el acceso a Internet
resource "aws_internet_gateway" "cloud_igw" {
  vpc_id = aws_vpc.cloud_vpc.id

  tags = {
    Name = "cloud-igw"
  }
}

# Crear una tabla de rutas y asociarla a las subredes
resource "aws_route_table" "cloud_route_table" {
  vpc_id = aws_vpc.cloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_igw.id
  }

  tags = {
    Name = "cloud-route-table"
  }
}

resource "aws_route_table_association" "subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.cloud_route_table.id
}

resource "aws_route_table_association" "subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.cloud_route_table.id
}

# Crear un Security Group para permitir tráfico HTTP y SSH
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.cloud_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "alb-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Crear las instancias EC2 en las subredes (con Nginx como servidor web)
resource "aws_instance" "appweb1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.alb_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    echo "<html><h1>Instancia App Web 1</h1></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "appweb2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_2.id
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.alb_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    echo "<html><h1>Instancia App Web 2</h1></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "WebServer2"
  }
}

# Crear un Target Group para el ALB (grupo de destino)
resource "aws_lb_target_group" "target_group" {
  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloud_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 5        # Puedes aumentar el intervalo si es necesario
    timeout  = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Crear un Application Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = "cloud-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "cloud-alb"
  }
}

# Crear un Listener para el ALB (para recibir tráfico HTTP en el puerto 80)
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Asociar las instancias EC2 al Target Group
resource "aws_lb_target_group_attachment" "appweb1_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.appweb1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "appweb2_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.appweb2.id
  port             = 80
}

# Crear una clave SSH
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Crear un grupo de subredes de la base de datos (usando las subredes existentes)
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "cloud-db-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "cloud-db-subnet-group"
  }
}

# Crear un Security Group para permitir tráfico hacia la base de datos
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.cloud_vpc.id

  ingress {
    from_port   = 3306   # Puerto MySQL
    to_port     = 3306
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
    Name = "cloud-db-sg"
  }
}

# Crear una base de datos RDS MySQL
resource "aws_db_instance" "mysql" {
  identifier              = "cloud-mysql-db"
  engine                  = "mysql"         
  instance_class          = "db.t3.micro"   
  allocated_storage       = 20              
  db_name                 = "cloudappdb"    
  username                = "admin"         
  password                = "adminpassword123"  
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name 
  vpc_security_group_ids  = [aws_security_group.db_sg.id]            
  skip_final_snapshot     = true    
  publicly_accessible     = true    
  multi_az                = false   
  backup_retention_period = 7       
  engine_version          = "8.0"   

  tags = {
    Name = "cloud-mysql-db"
  }
}

