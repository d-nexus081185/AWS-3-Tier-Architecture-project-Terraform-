#/bin/bash
sudo apt update -y
sudo apt install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

 sudo apt update -y
    sudo apt install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
    echo "<html><body><h1>I AM CHUKWUEMEKA EZEOBI; TERRAFORM IS MY NEW SUPER POWER</h1></body></html>" > /var/www/html/index.html