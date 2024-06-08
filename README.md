AWS 3-Tier Architechture using Terraform

The 3 Tier Architechture in AWS simply refers to a network topology that contains 3 part system:
1. Web Tier - A web presentation/interface for user intraction
2. Application Tier - The logic/heart of the architechture
3. Database Tier - This is where the information/user data is stored and managed.

The Steps in creating this project:
1. Create an IAM user from the AWS console and authenticate it with terraform using aws configure 
#Resource Creation:
2. Create VPC and assign CIDR 
3. Create Public and Private subnets of differnent AZ [availbilty zones] for redundancy and availability [ 6 subnets; 2 public subnets for the web tier, 2 private subnets for the application tier and 2 other private subnets for the database tier with assigned CIDR]. ** Attach each subnet to the VPC created for the project **
4. Create the Internet gateway and attach to the created VPC for the project
5. Create the NAT gateway
6. Create route tables [Public/private]; Assign the default gateway to the internet (0.0.0.0/0) and attach to the VPC and IGW. Also attach the public and private subnets respectively to the route tables.
7.  Configure the launch Templates
8. User data<br>
#User date configuration [Shell Script to install apache2 webserver and run the simple html file -index.html]<br>
  user_data = base64encode (<<-EOF<br>
    #!/bin/bash<br>
    sudo apt update -y
    sudo apt install -y apache2<br>
    sudo systemctl start apache2<br>
    sudo systemctl enable apache2<br>
    echo "<html><body><h4>I AM CHUKWUEMEKA EZEOBI; TERRAFORM IS MY NEW SUPER POWER</h4></body></html>" > /var/www/html/index.html
  EOF
  )

9. Auto Scaling Groups

10. Database Tier [mysql -h [database.endpoint.id] -P 3306 -u [MySql.User] -p [MySql.Password]]<br>
Install MySql on the Application tier server in both instances<br>
sudo apt update -y<br>
sudo apt install -y mysql-server<br>
sudo systemctl start mysql<br>
sudo systemctl enable mysql<br>

11. Testing 