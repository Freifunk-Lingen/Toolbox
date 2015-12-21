#!/bin/bash
read -p "First of all the New Hostname" Hostname
hostnamectl set-hostname $HOSTNAME
echo "Going to Install Software"
	echo "Installing Installation Helper Software"
		apt-get install lynx -y
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
echo "Going over to Configure the Software"
	echo "Configure PowerDNS..."
		sed 's/# recursor/recursor=8.8.8.8/g' /etc/powerdns/pdns.conf
	echo "Configure MySQL Replication..."
		echo "Sync Database..."
			scp service@pdns1.fflin.link:/STORAGE/mysqlbackup/latest.sql /tmp/latest.sql
			echo "Login to your MySQL Servers Root Account:"
			read -p "ROOT Password: " MySQLPW
			mysql -u root -p $MySQLPW < cat /tmp/latest.sql
		
		echo "Adding Service User to Local MySQL Server"
			read -p "Choose Password for Service Account: " MySQLServicePW
			mysql -u root -p $MySQLPW -c "CREATE USER 'service'@'localhost' IDENTIFIED BY '"$MySQLServicePW"';"
			mysql -u root -p $MySQLPW -c "GRANT USAGE ON *.* TO 'service'@'localhost';"
		
		echo "Enforce Policies and Rights for Service User"
			mysql -u root -p $MySQLPW -c  "GRANT SELECT, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE, LOCK TABLES  ON `pdns`.* TO 'service'@'localhost' WITH GRANT OPTION;"
			mysql -u root -p $MySQLPW -c "FLUSH PRIVILEGES;"
		
	echo "Configure PowerAdmin..."
		echo "Creating Webserver Configuration..."
			echo "<VirtualHost *:8080>" >> /etc/apache2/sites-available/poweradmin.conf
			echo "DocumentRoot /var/www/poweradmin" >> /etc/apache2/sites-available/poweradmin.conf
			echo "</VirtualHost>" >> /etc/apache2/sites-available/poweradmin.conf
		echo "Doing Installation on Shell"
			lynx http://localhost:8080 -accept_all_cookies
	echo "Configure Webmin..."
		echo "Loading Bootstrap Theme"
			wget http://theme.winfuture.it/bwtheme.wbt.gz -O /tmp/bwtheme.wbt.tgz
			cd /tmp/
			tar xvf bwtheme.wbt.tgz
			mv bootstrap /usr/share/webmin/
			sed 's/theme=?/theme=bootstrap/g' /etc/webmin/config -i
		echo "Disable Autostart"
			systemctl disable webmin
echo "Going to register this DNS Server to Master DNS Server"
	echo "Connecting to Master..."
		echo "Add Server to Zone"
		clear
		mapfile -t lines < <(ip addr show | grep inet | grep eth0 | awk {'print $2'} | cut -d'/' -f1)
		
		for (( i=0; i < ${#lines[@]} ; i++ )); do 
			printf "%s: %s\n" "$i" "${lines[i]}"
		done
		read -p "Choose IPv4 Address to Use for A-Record: " IPv4
		IPv4=${lines[$IPv4]}
		
		clear
		mapfile -t lines < <(ip addr show | grep inet6 | grep global | awk {'print $2'} | cut -d'/' -f1)
		for (( i=0; i < ${#lines[@]} ; i++ )); do 
			printf "%s: %s\n" "$i" "${lines[i]}"
		done
		read -p "Choose IPv6 Address to Use for AAAA-Record: " IPv6
		IPv6=${lines[$IPv6]}
		
		echo "A-Record: " $IPv4
		echo "AAAA-Record: " $IPv6
		echo "Hostname: " $HOSTNAME
		
		mysql -u root -p $MySQLPW -c "INSERT INTO records (domain_id,name,type,content,ttl,disabled,auth) VALUES (2,'"$HOSTNAME"','A','"$IPv4"',86400,0,1)" pdns
		mysql -u root -p $MySQLPW -c "INSERT INTO records (domain_id,name,type,content,ttl,disabled,auth) VALUES (2,'"$HOSTNAME"','AAAA','"$IPv6"',86400,0,1)" pdns
		unset MySQLPW
		unset MySQLServicePW
	