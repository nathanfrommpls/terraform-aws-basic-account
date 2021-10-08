#!/bin/bash
sudo apt -y update
sudo apt -y install apache2 wget
sudo echo "<html><body><h1>Testing</h1></body></html>" > /var/www/html/index.html
cd /tmp/
wget https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i /tmp/amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent apache2
sudo systemctl start amazon-ssm-agent apache2
