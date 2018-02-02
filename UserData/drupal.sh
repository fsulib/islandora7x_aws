echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseEndpoint: ${DATABASE_ENDPOINT}" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "DrupalDatabaseUser: ${DRUPAL_DATABASE_USER}" >> /root/build-params.txt
echo "DrupalDatabasePass: ${DRUPAL_DATABASE_PASS}" >> /root/build-params.txt

# Mount external devices 
mkfs -t ext4 /dev/xvdb
mkfs -t ext4 /dev/xvdc
cp -pr /var /tmp
cp -pr /home /tmp 
mount /dev/xvdb /var
mount /dev/xvdc /home
cp -pr /etc/fstab /etc/fstab.orig
echo "/dev/xvdb   /var        ext4    defaults,nofail 0   2" >> /etc/fstab
echo "/dev/xvdc   /home       ext4    defaults,nofail 0   2" >> /etc/fstab
mount -a
cp -prT /tmp/var /var
cp -prT /tmp/home /home
rm -rf /tmp/var
rm -rf /tmp/home

# Set timezone
rm -f /etc/localtime
cd /etc
ln -s /usr/share/zoneinfo/US/Eastern localtime

# Run updates & installations
yum -y update > /root/updates.txt
yum -y install httpd mysql ImageMagick > /root/installs.txt
yum -y install php php-devel php-gd php-xml php-soap php-mysql php-mbstring > /root/installs.php.txt

# Configure MySQL
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE DATABASE drupaldb;" >> /root/mysql.log 2>&1
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE USER '${DRUPAL_DATABASE_USER}'@'10.50.0.101' IDENTIFIED BY '${DRUPAL_DATABASE_PASS}';" >> /root/mysql.log 2>&1
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="GRANT ALL PRIVILEGES ON drupaldb.* TO ${DRUPAL_DATABASE_USER}@10.50.0.101;" >> /root/mysql.log 2>&1
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="FLUSH PRIVILEGES;" >> /root/mysql.log 2>&1

# Configure Drupal
mkdir /root/.composer
export COMPOSER_HOME=/root/.composer
curl -sS https://getcomposer.org/installer -o /root/composer-installer.php 
php /root/composer-installer.php --install-dir=/root/.composer
php /root/.composer/composer.phar global require drush/drush:7.1.0
rm -rf /var/www/html
/root/.composer/vendor/bin/drush dl drupal-7.x --destination=/var/www/ --drupal-project-rename=html
cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
/root/.composer/vendor/bin/drush --root=/var/www/html --uri=default -y si standard --account-name=admin --account-pass=admin --db-url=mysql://$DRUPAL_DATABASE_USER:$DRUPAL_DATABASE_PASS@$DATABASE_ENDPOINT/drupaldb --site-name=Islandora
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="ALTER DATABASE drupaldb CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;"
sed -i -e "s/'prefix'\ =>\ '',/'prefix'\ =>\ '',\ 'charset'\ =>\ 'utf8mb4',\ 'collation'\ =>\ 'utf8mb4_general_ci',/g" /var/www/html/sites/default/settings.php
chmod -R 777 /var/www/html

# Configure apache
echo "AddHandler php5-script .php" >> /etc/httpd/conf/httpd.conf
echo "AddType text/html .php" >> /etc/httpd/conf/httpd.conf
sed -i -e 's/AllowOverride\ None/AllowOverride\ All/g' /etc/httpd/conf/httpd.conf
service httpd restart
