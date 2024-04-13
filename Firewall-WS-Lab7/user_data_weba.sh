#!/bin/bash -ex

# Install packages:
yum update -y;
yum install jq -y;
yum install httpd -y;
yum install htop -y;
# Configure hostname:
hostnamectl set-hostname WebInstanceA;
# Define variables:
curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document > /home/ec2-user/iid;
export instance_az=$(cat /home/ec2-user/iid |grep 'availability' | awk -F': ' '{print $2}' | awk -F',' '{print $1}');
export instance_ip=$(cat /home/ec2-user/iid |grep 'privateIp' | awk -F': ' '{print $2}' | awk -F',' '{print $1}' | awk -F'"' '{print$2}');
export instance_region=$(cat /home/ec2-user/iid |grep 'region' | awk -F': ' '{print $2}' | awk -F',' '{print $1}' | awk -F'"' '{print$2}');
# Add index.html
touch /var/www/html/index.html;
cat <<EOT >> /var/www/html/index.html
<html>
  <head>
    <title>Test Web Server</title>
    <meta http-equiv='Content-Type' content='text/html; charset=ISO-8859-1'>
  </head>
  <body>
    <h1>Welcome to AWS Network Firewall Workshop:</h1>
    <h2>This is a simple web server running in $instance_az.</h2>
  </body>
</html>
EOT
# Enable and start httpd
systemctl enable httpd;
systemctl start httpd;