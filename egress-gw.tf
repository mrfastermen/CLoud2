resource "aws_egress_only_internet_gateway" "egress-gw" {
  vpc_id = aws_vpc.cloud2_vpc.id

  tags = {
    Name = "egress-gw"
  }
}