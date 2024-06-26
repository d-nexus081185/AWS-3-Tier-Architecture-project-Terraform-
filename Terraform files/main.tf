# Author    : Chukwuemeka Ezeobi
# Email     : emekaezeobi@outlook.com
# GitHub    : https://github.com/d-nexus081185
################################################

# VPC Resource Creation
resource "aws_vpc" "_3-tierproject-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "_3-tierproject-VPC"
  }
}

# Internet Gateway Resource Creation
resource "aws_internet_gateway" "_3-tierproject-igw" {
  vpc_id = aws_vpc._3-tierproject-vpc.id

  tags = {
    Name = "_3-tierproject-igw"
  }
}

# Route Table Resource - PublicRT
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

# Route Table Resource - PrivateRT
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

# Subnet Resource -Public1 [With different AZ]
resource "aws_subnet" "web-tier1-public" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "web-tier1-public"
  }
}
# Subnet Resource -Public2 [With different AZ]
resource "aws_subnet" "web-tier2-public" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "web-tier2-public"
  }
}

# Subnet Resource -private1 [With different AZ]
resource "aws_subnet" "application-tier1-private" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  #map_public_ip_on_launch = "true"

  tags = {
    Name = "application-tier1-private"
  }
}
# Subnet Resource -private1 [With different AZ]
resource "aws_subnet" "application-tier2-private" {
  vpc_id     =  aws_vpc._3-tierproject-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  #map_public_ip_on_launch = "true"

  tags = {
    Name = "application-tier2-private"
  }
}

#Subnet Association to Route Table [Public]
resource "aws_route_table_association" "Association-public1-subnet" {
  subnet_id      = aws_subnet.web-tier1-public.id
  route_table_id = aws_route_table._3-tierproject-public_rt.id
}
resource "aws_route_table_association" "Association-public2-subnet" {
  subnet_id      = aws_subnet.web-tier2-public.id
  route_table_id = aws_route_table._3-tierproject-public_rt.id
}
#Subnet Association to Route Table [Private]
resource "aws_route_table_association" "Association-private1-subnet" {
  subnet_id      = aws_subnet.application-tier1-private.id
  route_table_id = aws_route_table._3-tierproject-private_rt.id
}
resource "aws_route_table_association" "Association-private2-subnet" {
  subnet_id      = aws_subnet.application-tier2-private.id
  route_table_id = aws_route_table._3-tierproject-private_rt.id
}

# Security Group Resource -web-tier
resource "aws_security_group" "_3-web-tierproject-SG" {
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
    Name = "_3-web-tierproject-SG"
  }
}

# Security Group Resource - application-tier
resource "aws_security_group" "_3-application-tierproject-SG" {
  vpc_id = aws_vpc._3-tierproject-vpc.id
  name        = "_3-application-tierproject-SG"
  description = "Allow inbound traffic"

  # Allow SSH only from the web-tier subnet
  ingress {
    description      = "SSH access from web-tier subnet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [
      aws_subnet.web-tier1-public.cidr_block,
      aws_subnet.web-tier2-public.cidr_block
    ]
  }


  ingress {
    description      = "HTTP access"   # Allow HTTP access from anywhere
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "MySQL access"  # Allow MySQL access from anywhere
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "_3-application-tierproject-SG"
  }
}

# Launch Template Resource -web-tier
resource "aws_launch_template" "_3-web-tierproject-lt" {
  name_prefix   = "_3-web-tierproject-"
  image_id      = "ami-04b70fa74e45c3917" # Replace with your desired AMI ID
  instance_type = "t2.micro"     # Replace with your desired instance type

  key_name = "tf-key"     # Replace with your key pair name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group._3-web-tierproject-SG.id]
    subnet_id                   = aws_subnet.web-tier1-public.id  # Replace with your desired subnet ID
  }

  #User date configuration [Shell Script to install apache2 webserver and run the simple html file -index.html]
  user_data = base64encode (<<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<html><body><h1>I AM CHUKWUEMEKA EZEOBI; TERRAFORM IS MY NEW SUPER POWER</h1></body></html>" > /var/www/html/index.html
  EOF
  )

  tags = {
    Name = "_3-web-tierproject-lt"
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

# Launch Template Resource -application-tier
resource "aws_launch_template" "_3-application-tierproject-lt" {
  name_prefix   = "_3-tierproject-"
  image_id      = "ami-04b70fa74e45c3917" # Replace with your desired AMI ID
  instance_type = "t2.micro"     # Replace with your desired instance type

  key_name = "tf-key"     # Replace with your key pair name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group._3-application-tierproject-SG.id]
    subnet_id                   = aws_subnet.application-tier1-private.id  # Replace with your desired subnet ID
  }

  #User date configuration [Shell Script to install MySql on the Application tier]
  #user_data = base64encode (<<-EOF
    #!/bin/bash
    #sudo apt update -y
    #sudo apt install -y mysql-server
    #sudo systemctl start mysql
    #sudo systemctl enable mysql
  #EOF
  #)
  
  tags = {
    Name = "_3-application-tierproject-lt"
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

# Auto Scaling Group -web-tier
resource "aws_autoscaling_group" "_3-web-tierproject-asg" {
  desired_capacity     = 2
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [
    aws_subnet.web-tier1-public.id,
    aws_subnet.web-tier2-public.id
  ]

  launch_template {
    id      = aws_launch_template._3-web-tierproject-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Web-Server-Demo"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
  
}

# Auto Scaling Group -application-tier
resource "aws_autoscaling_group" "_3-application-tierproject-asg" {
  desired_capacity     = 2
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [
    aws_subnet.application-tier1-private.id,
    aws_subnet.application-tier2-private.id
  ]

  launch_template {
    id      = aws_launch_template._3-application-tierproject-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Application-Server-Demo"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
}

# DB Instance
resource "aws_db_instance" "application-tier_DB" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Password123!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group._3-application-tierproject-SG.id]
  db_subnet_group_name   = aws_db_subnet_group.mydb-subnet-group.name
}

# DB Subnet Group
resource "aws_db_subnet_group" "mydb-subnet-group" {
  name       = "mydb-subnet-group"
  subnet_ids = [aws_subnet.application-tier1-private.id, aws_subnet.application-tier2-private.id]

  tags = {
    Name = "mydb-subnet-group"
  }
}