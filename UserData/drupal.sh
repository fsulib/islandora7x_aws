# Save build parameters
echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseEndpoint: ${DATABASE_ENDPOINT}" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "DrupalDatabaseUser: ${DRUPAL_DATABASE_USER}" >> /root/build-params.txt
echo "DrupalDatabasePass: ${DRUPAL_DATABASE_PASS}" >> /root/build-params.txt
echo "DrupalAdminUser: ${DRUPAL_ADMIN_USER}" >> /root/build-params.txt
echo "DrupalAdminPass: ${DRUPAL_ADMIN_PASS}" >> /root/build-params.txt
echo "DrupalAdminEmail: ${DRUPAL_ADMIN_EMAIL}" >> /root/build-params.txt
echo "DrupalSiteName: ${DRUPAL_SITE_NAME}" >> /root/build-params.txt
echo "CustomShScriptUrl: ${CUSTOM_SH_SCRIPT_URL}" >> /root/build-params.txt


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
yum -y install httpd mysql ImageMagick git > /root/installs.txt
yum -y install php php-devel php-gd php-xml php-soap php-mysql php-mbstring > /root/installs.php.txt


# Configure MySQL
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE DATABASE drupaldb;" >> /root/mysql.log 2>&1
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE USER '${DRUPAL_DATABASE_USER}'@'%' IDENTIFIED BY '${DRUPAL_DATABASE_PASS}';" >> /root/mysql.log 2>&1
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="GRANT ALL PRIVILEGES ON drupaldb.* TO '${DRUPAL_DATABASE_USER}'@'%';" >> /root/mysql.log 2>&1
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
/root/.composer/vendor/bin/drush --root=/var/www/html --uri=default -y si standard --account-name=$DRUPAL_ADMIN_USER --account-pass=$DRUPAL_ADMIN_PASS --account-mail=$DRUPAL_ADMIN_EMAIL --db-url=mysql://$DRUPAL_DATABASE_USER:$DRUPAL_DATABASE_PASS@$DATABASE_ENDPOINT/drupaldb --site-name="$DRUPAL_SITE_NAME"
chmod -R 755 /var/www/html


# Configure HTTPD 
echo "AddHandler php5-script .php" >> /etc/httpd/conf/httpd.conf
echo "AddType text/html .php" >> /etc/httpd/conf/httpd.conf
sed -i -e 's/AllowOverride\ None/AllowOverride\ All/g' /etc/httpd/conf/httpd.conf
service httpd restart


# Install core Islandora modules
#wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/core_islandora_modules.txt -O /tmp/core_islandora_modules.txt
#while read line
#do
#  cd /var/www/html/sites/all/modules/
#  git clone https://github.com/Islandora/$line
  # /root/.composer/vendor/bin/drush -y --root=/var/www/html en $line
#done < /tmp/core_islandora_modules.txt

# Download tuque library and enable libraries module
cd /var/www/html/sites/all/libraries
git clone https://github.com/Islandora/tuque.git /var/www/html/sites/all/libraries/tuque
cd /var/www/html
/root/.composer/vendor/bin/drush --user=1 en libraries -y

# Set Fedora URL and enable Islandora
git clone https://github.com/Islandora/islandora.git /var/www/html/sites/all/modules/islandora
/root/.composer/vendor/bin/drush vset islandora_base_url "http://10.50.0.102:8080/fedora"
/root/.composer/vendor/bin/drush --user=1 en islandora -y

# Enable the Basic Collection module
git clone https://github.com/Islandora/islandora_solution_pack_collection.git /var/www/html/sites/all/modules/islandora_solution_pack_collection
/root/.composer/vendor/bin/drush --user=1 en islandora_basic_collection -y

# Enable the Basic Image module
/root/.composer/vendor/bin/drush dl imagemagick
/root/.composer/vendor/bin/drush en imagemagick -y
git clone https://github.com/Islandora/islandora_solution_pack_image.git /var/www/html/sites/all/modules/islandora_solution_pack_image
/root/.composer/vendor/bin/drush --user=1 en islandora_basic_image -y

# Run custom provisioning
wget $CUSTOM_SH_SCRIPT_URL -O /tmp/custom.sh
chmod +x /tmp/custom.sh
#sh /tmp/custom.sh

# Final refresh of system before exiting
/root/.composer/vendor/bin/drush --root=/var/www/html --uri=default -y cc all
service httpd restart
