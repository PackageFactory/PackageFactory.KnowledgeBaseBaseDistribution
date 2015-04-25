#!/bin/bash

php_config_file="/etc/php5/apache2/php.ini"
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"
mysql_config_file="/etc/mysql/my.cnf"

# Fix message "stdin: is not a tty"s
sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile

IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
sed -i "s/^${IPADDR}.*//" /etc/hosts
echo $IPADDR ubuntu.localhost >> /etc/hosts			# Just to quiet down some error messages

# Update the server
#apt-get update
#apt-get -y upgrade

# Install basic tools
apt-get -y install build-essential binutils-doc git

# Install Apache
apt-get -y install apache2
apt-get -y install php5 php5-curl php5-mysql php5-sqlite php5-xdebug php5-gd

sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
sed -i "s/display_errors = Off/display_errors = On/g" ${php_1_file}
echo "xdebug.remote_enable=On" >> ${xdebug_config_file}
echo 'xdebug.remote_connect_back=On' >> ${xdebug_config_file}

# Install MySQL
echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-client mysql-server

sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" ${mysql_config_file}

# Allow root access from any host
echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql -u root --password=root
echo "GRANT PROXY ON ''@'' TO 'root'@'%' WITH GRANT OPTION" | mysql -u root --password=root

# Install mailcatcher
apt-get -y install ruby1.9.1-dev libsqlite3-dev
gem install mailcatcher
mailcatcher --http-ip=0.0.0.0
sed -i "s/smtp_port = 25/smtp_port = 1025/g" ${php_config_file}
sed -i "s/;sendmail_path =/sendmail_path = \/usr\/bin\/env catchmail \-f some@from.address/g" ${php_config_file}

# Install nodejs
apt-get -y install nodejs npm
ln -nsf /usr/bin/nodejs /usr/bin/node

# Install sass
gem install sass

# Create dev Database
echo "CREATE DATABASE packagefactory_knowledgebase_dev collate utf8_unicode_ci;" | mysql -u root -proot

# Create Symlink for Webdirectory
ln -s /home/vagrant/project/Web /var/www/html

# Restart Services
service apache2 restart
service mysql restart