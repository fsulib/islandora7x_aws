#!/bin/bash

yum -y update > /root/updates.txt
yum -y install httpd mysql mysql-server ImageMagick
yum -y install php php-devel php-gd php-xml php-soap php-mysql php-mbstring > /root/installs.php.txt

# Configure MySQL
service mysqld start
chkconfig mysqld on
mysql -e "CREATE DATABASE islandoradb;"
mysql -e "CREATE USER 'islandora'@'localhost' IDENTIFIED BY 'islandora';"
mysql -e "GRANT ALL PRIVILEGES ON islandoradb.* TO islandora@localhost;"
mysql -e "FLUSH PRIVILEGES;"

# Configure Drupal
curl -sS https://getcomposer.org/installer -o /root/composer-installer.php 
php /root/composer-installer.php --install-dir=/root
php /root/composer.phar global require drush/drush:7.1.0
rm -rf /var/www/html
/root/.composer/vendor/bin/drush dl drupal-7.x --destination=/var/www/ --drupal-project-rename=html
cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php

/root/.composer/vendor/bin/drush --root=/var/www/html --uri=default -y si standard --account-name=admin --account-pass=admin --db-url=mysql://islandora:islandora@localhost/islandoradb --site-name=Islandora

mysql -e "ALTER DATABASE islandoradb CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;"

chmod -R 777 /var/www/html

# Configure apache
echo "AddHandler php5-script .php" >> /etc/httpd/conf/httpd.conf
echo "AddType text/html .php" >> /etc/httpd/conf/httpd.conf
sed -i -e 's/AllowOverride\ None/AllowOverride\ All/g' /etc/httpd/conf/httpd.conf
service httpd restart
