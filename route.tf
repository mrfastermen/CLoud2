resource "aws_route_table" "cloud2routePrivate" {
  vpc_id = aws_vpc.cloud2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud2-gw.id
  }

  tags = {
    Name = "cloud2routePrivate"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.privada1.id
  route_table_id = aws_route_table.cloud2routePrivate.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.privada2.id
  route_table_id = aws_route_table.cloud2routePrivate.id
}