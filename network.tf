
resource "aws_vpc" "Webapp" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "server VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.Webapp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Subnet = "Public"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.Webapp.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Subnet = "Public_2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.Webapp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Subnet = "Private_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.Webapp.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    subnet = "Private_2"
  }
}

resource "aws_internet_gateway" "Webapp" {
  vpc_id = aws_vpc.Webapp.id
  tags = {
    Name = "server IG"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.Webapp.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Webapp.id
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat_gateway"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.Webapp.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id

}





