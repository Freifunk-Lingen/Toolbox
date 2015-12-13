#!/bin/bash
echo "Going to Install Software"
	echo "Installing PowerDNS..."
		apt-get install pdns-server pdns-backend-mysql -y
	echo "Installing MySQL..."
		apt-get install mysql-server mysql-client -y
	echo "Installing powerAdmin..."
		apt-get install apache2 libapache2-mod-php5 php5 php5-common php5-curl php5-dev php5-gd php-pear php5-imap php5-mcrypt php5-mhash php5-ming php5-mysql php5-xmlrpc gettext -y
		php5enmod mcrypt
		systemctl restart apache2
		wget http://downloads.sourceforge.net/project/poweradmin/poweradmin-2.1.7.tgz -O /tmp/poweradmin.tgz
		tar xvf /tmp/poweradmin.tgz
		mv /tmp/poweradmin*.tgz /var/www/poweradmin
	echo "Installing Webmin..."
		echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list.d/webmin.list
		echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list.d/webmin.list
		wget http://www.webmin.com/jcameron-key.asc -O /tmp/webmin.asc
		apt-key add /tmp/webmin.asc
		apt-get update
		apt-get install webmin
echo "Going over to Configuration the Software"
	echo "Configure PowerDNS..."
		sed 's/# recursor/recursor=8.8.8.8/g' /etc/powerdns/pdns.conf
	echo "Configure MySQL Replication..."
	echo "Configure PowerAdmin..."
		echo "Doing Installation on Shell"
		echo "Creating Webserver Configuration..."
	echo "Configure Webmin..."
		echo "Loading Bootstrap Theme"
		echo "Disable Autostart"
			systemctl disable webmin
	echo "Configure SSL Keys..."
echo "Going over to Configure the System"
	echo "Set up User for MySQL Replication..."
	echo "Configure SSH and SSH Tunnel for MySQL Replication..."
echo "Enforce Security Policies"
echo "Going to register this DNS Server to Master DNS Server"
	