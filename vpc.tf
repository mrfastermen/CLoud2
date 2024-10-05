resource "aws_vpc" "cloud2_vpc" {
  cidr_block       = "30.0.0.0/16"

  tags = {
    Name = "cloud2_vpc"
  }
}