#!/bin/bash

php_config_file="/etc/php5/apache2/php.ini"
xdebug_config_file="/etc/php5/mods-available/xdebug.ini"
PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
PG_DIR="/var/lib/postgresql/$PG_VERSION/main"

# Edit the following to change the name of the database user that will be created:
APP_DB_USER=vagrant
APP_DB_PASS=vagrant

# Edit the following to change the name of the database that is created (defaults to the user name)
APP_DB_NAME=packagefactory_knowledgebase_dev

# Edit the following to change the version of PostgreSQL that is installed
PG_VERSION=9.3

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
apt-get -y install php5 php5-curl php5-pgsql php5-sqlite php5-xdebug php5-gd

sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
sed -i "s/display_errors = Off/display_errors = On/g" ${php_1_file}
echo "xdebug.remote_enable=On" >> ${xdebug_config_file}
echo 'xdebug.remote_connect_back=On' >> ${xdebug_config_file}

# Install Postgresql
apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"

# Append to pg_hba.conf to add password auth:
echo "host    all             all             all                     md5" >> "$PG_HBA"

# Explicitly set default client_encoding
echo "client_encoding = utf8" >> "$PG_CONF"

# Restart so that all new config is loaded:
service postgresql restart

# Create a database User
cat << EOF | su - postgres -c psql
  CREATE ROLE $APP_DB_USER WITH LOGIN PASSWORD '$APP_DB_PASS'
EOF

# Create the database
cat << EOF | su - postgres -c psql
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
  LC_COLLATE='en_US.utf8'
  LC_CTYPE='en_US.utf8'
  ENCODING='UTF8'
  TEMPLATE=template0;
EOF

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

# Install grunt
npm install -g grunt-cli

# Create Symlink for Webdirectory
ln -s /home/vagrant/project/Web /var/www/html

# copy vhost
cp /home/vagrant/project/Vagrant/vhost.conf /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
a2enmod rewrite

# Restart Services
service apache2 restart
