resource "aws_internet_gateway" "cloud2-gw" {
  vpc_id = aws_vpc.cloud2_vpc.id

  tags = {
    Name = "cloud2-gw"
  }
}