#!/bin/bash
read -p "First of all the New Hostname" Hostname
	hostnamectl set-hostname $HOSTNAME
echo "Creating SSH Keys"
	ssh-keygen
	read -p "Please Copy the Public Key to the authorized_keys file from the Central MySQL Server"
	clear
	cat ~/.ssh/id_rsa.pub
	clear
echo "Going to Install Software"
	echo "Installing PowerDNS..."
		apt-get install pdns-server pdns-backend-mysql -y
	echo "Installing MySQL..."
		apt-get install mysql-server mysql-client -y
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
			echo "Login to your MySQL Servers pdns Account:"
			read -p "'pdns' User Password: " MySQLPW
			ssh fflin@alnilam.uberspace.de \ 'mysqldump fflin_pdns' \ | mysql -u pdns -p$MySQLPW pdns
			line="* * * * * ssh fflin@alnilam.uberspace.de \ 'mysqldump fflin_pdns' \ | mysql -u pdns -p$MySQLPW pdns"
			(crontab -u root -l; echo "$line" ) | crontab -u root -
	echo "Configure Webmin..."
		echo "Loading Bootstrap Theme"
			wget http://theme.winfuture.it/bwtheme.wbt.gz -O /tmp/bwtheme.wbt.tgz
			cd /tmp/
			tar xvf bwtheme.wbt.tgz
			mv bootstrap /usr/share/webmin/
			sed 's/theme=?/theme=bootstrap/g' /etc/webmin/config -i
			sed 's/preroot=?/preroot=bootstrap/g' /etc/webmin/miniserv.conf -i
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
		
		ssh fflin@alnilam.uberspace.de \ 'mysql -c "INSERT INTO records (domain_id,name,type,content,ttl,disabled,auth) VALUES (2,'"$HOSTNAME"','A','"$IPv4"',86400,0,1)" fflin_pdns' \
		ssh fflin@alnilam.uberspace.de \ 'mysql -c "INSERT INTO records (domain_id,name,type,content,ttl,disabled,auth) VALUES (2,'"$HOSTNAME"','AAAA','"$IPv6"',86400,0,1)" fflin_pdns' \
		unset MySQLPW
		unset MySQLServicePW
	
