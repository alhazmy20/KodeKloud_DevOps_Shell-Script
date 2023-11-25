#!/bin/bash

function install_packages(){
for package in $(cat required-packages.txt)
do
	sudo yum install -y $package
done
}

function start_and_enable_services(){
for service in httpd mariadb firewalld
do	
	status=$(sudo systemctl status $service)
	if [[ $status = *running* || $status = *enabled\;* ]]
	then
		echo "$service is already running and started"
	else
		echo "Starting the $service service"
		sudo systemctl start $service
		echo "Enabling the $service service"
		sudo systemctl enable $service
	fi
done
}

function add_ports_to_firewall(){
for port in 3306 80
do
	ports=$(netstat -tuln | grep -we 3306 -we 80)
	if [[ $port = *3306* || $port = *80* ]]
	then 
		echo "$port port is already added to the firewall"
	else
		echo "Adding $port port to the firewall"	
		sudo firewall-cmd --permanent --zone=public --add-port=$port/tcp
	fi
done
}

function check_item_exists(){
source_page=$1
item=$2
if [[ $source_page = *$2* ]]
then
	echo "Item $2 exists in the page"
else
	echo "Item $2 does not exists on the page"
fi
}

#Functions calling
install_packages
start_and_enable_services
add_ports_to_firewall

#Configuring the database 
mysql -u root < db-configure.sql
#Load the the database
mysql -u ecomuser -pecompassword < db-load.sql

#Cloning the project from github repos
git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#Configure the http default page from index.html to index.php
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#Updating the index.php database connection to use the localhost db
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

#print the source code of the page
source_page=$(curl http://localhost)

#check if the item exists in the web page
for item in $(cat products.txt)
do
	check_item_exists "$source_page" $item
done
