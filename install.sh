#/bin/bash
sudo apt update -y
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl status mysql
mysql -h [database.endpoint.id] -P 3306 -u [MySql.User] -p [MySql.Password}

 sudo apt update -y
    sudo apt install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<html><body><h4>I AM CHUKWUEMEKA EZEOBI; TERRAFORM IS MY NEW SUPER POWER</h4></body></html>" > /var/www/html/index.
    

