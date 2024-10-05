resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.cloud2_vpc.id
  cidr_block = "30.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.cloud2_vpc.id
  cidr_block = "30.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public2"
  }
}

resource "aws_subnet" "privada1" {
  vpc_id     = aws_vpc.cloud2_vpc.id
  cidr_block = "30.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "privada1"
  }
}

resource "aws_subnet" "privada2" {
  vpc_id     = aws_vpc.cloud2_vpc.id
  cidr_block = "30.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "privada2"
  }
}