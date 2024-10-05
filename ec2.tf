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

resource "aws_instance" "cloud2-instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id = aws_subnet.public1.id # Asociar la instancia a la subred

  # Seguridad de la instancia (acceso solo por SSH - puerto 22)
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "cloud2-instance"
  }
}

resource "aws_instance" "cloud2-instance2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  subnet_id = aws_subnet.public2.id # Asociar la instancia a la subred

  # Seguridad de la instancia (acceso solo por SSH - puerto 22)
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "cloud2-instance2"
  }
}