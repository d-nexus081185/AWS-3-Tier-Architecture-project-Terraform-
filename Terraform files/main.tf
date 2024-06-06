# VPC Resource
resource "aws_vpc" "_3-tierproject-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "_3-tierproject-VPC"
  }
}

# Internet Gateway Resource
resource "aws_internet_gateway" "_3-tierproject-igw" {
  vpc_id = aws_vpc._3-tierproject-vpc.id

  tags = {
    Name = "_3-tierproject-igw"
  }
}

# Route Table Resource - public
resource "aws_route_table" "_3-tierproject-public_rt" {
  vpc_id = aws_vpc._3-tierproject-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway._3-tierproject-igw.id
  }

  tags = {
    Name = "_3-tierproject-public_rt"
  }
}

# Create an Elastic IP for the NAT Gateway
resource "aws_eip" "_3-tierproject-nat_eip" {
  depends_on = [aws_internet_gateway._3-tierproject-igw]

  tags = {
    Name = "_3-tierproject-nat_eip"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "_3-tierproject-nat_gw" {
  allocation_id = aws_eip._3-tierproject-nat_eip.id
  subnet_id     = aws_subnet.web-tier1-public.id

  tags = {
    Name = "_3-tierproject-nat_gw"
  }
}

# Route Table Resource - private
resource "aws_route_table" "_3-tierproject-private_rt" {
  vpc_id = aws_vpc._3-tierproject-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway._3-tierproject-nat_gw.id
  }

  tags = {
    Name = "_3-tierproject-private_rt"
  }
}

# Subnet Resource -public
resource "aws_subnet" "web-tier1-public" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "web-tier1-public"
  }
}
resource "aws_subnet" "web-tier2-public" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "web-tier2-public"
  }
}

# Subnet Resource -private
resource "aws_subnet" "application-tier1-private" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "application-tier1-private"
  }
}
resource "aws_subnet" "application-tier2-private" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "application-tier2-private"
  }
}

#Associate Subnet to Route Table
resource "aws_route_table_association" "Association-public1-subnet" {
  subnet_id      = aws_subnet.web-tier1-public.id
  route_table_id = aws_route_table._3-tierproject-public_rt.id
}
resource "aws_route_table_association" "Association-public2-subnet" {
  subnet_id      = aws_subnet.web-tier2-public.id
  route_table_id = aws_route_table._3-tierproject-public_rt.id
}

resource "aws_route_table_association" "Association-private1-subnet" {
  subnet_id      = aws_subnet.application-tier1-private.id
  route_table_id = aws_route_table._3-tierproject-private_rt.id
}
resource "aws_route_table_association" "Association-private2-subnet" {
  subnet_id      = aws_subnet.application-tier2-private.id
  route_table_id = aws_route_table._3-tierproject-private_rt.id
}