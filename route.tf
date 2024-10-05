resource "aws_route_table" "cloud2routePublic" {
  vpc_id = aws_vpc.cloud2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud2-gw.id
  }

  tags = {
    Name = "cloud2routePublic"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.cloud2routePublic.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.cloud2routePublic.id
}