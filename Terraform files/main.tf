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

# Security Group Resource
resource "aws_security_group" "_3-tierproject-SG" {
  vpc_id = aws_vpc._3-tierproject-vpc.id
  name        = "_3-tierproject-SG"
  description = "Allow inbound traffic"

  ingress = [
    for port in [22, 80 ] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "_3-tierproject-SG"
  }
}


# Launch Template Resource
resource "aws_launch_template" "_3-tierproject-launch_template" {
  name_prefix   = "_3-tierproject-"
  image_id      = "ami-04b70fa74e45c3917" # Replace with your desired AMI ID
  instance_type = "t2.micro"     # Replace with your desired instance type

  key_name = "tf-key"     # Replace with your key pair name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group._3-tierproject-SG.id]
    subnet_id                   = aws_subnet.web-tier1-public.id  # Replace with your desired subnet ID
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y httpd
    sudo systemctl start httpd
    sudo systemctl enable https
    echo "<html><body><h1>New Website -Demo for 3Tier Application</h1></body></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "_3-tierproject-launch_template"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Define an Auto Scaling Group
resource "aws_autoscaling_group" "_3-tierproject-asg" {
  # Specify the name of the Auto Scaling Group
  name = "_3-tierproject-asg"

  # Launch configuration or launch template to use for the instances
  launch_configuration = aws_launch_template._3-tierproject-launch_template.id

  # Minimum and maximum number of instances in the Auto Scaling Group
  min_size = 1
  max_size = 2

  # Desired number of instances to maintain
  desired_capacity = 1

  # Subnets where instances will be launched
  vpc_zone_identifier = [aws_subnet.web-tier1-public.id, aws_subnet.web-tier2-public.id]  # Replace with your subnet IDs

  # Load Balancer names (optional)
  #load_balancers = ["example-elb"]  # Replace with your ELB name if using

  # Health check configuration
  #health_check_type        = "ELB"
  #health_check_grace_period = 300

}

