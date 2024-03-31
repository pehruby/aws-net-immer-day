#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sleep 60
date > /tmp/image.log
yum update -y
yum -y install httpd php mysql php-mysql ftp
systemctl enable --now httpd
systemctl start httpd
# configure web server:
cd /var/www/html
wget https://s3.amazonaws.com/immersionday-labs/bootcamp-app.tar
tar xvf bootcamp-app.tar
chown apache:root /var/www/html/rds.conf.php             