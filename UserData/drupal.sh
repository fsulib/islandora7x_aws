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
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime


# Run updates & installations
yum -y update > /root/updates.txt
yum -y install httpd mysql git > /root/installs.txt
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


# Pause to wait for Fedora until it is ready to recieve Islandora required objects
until [ $(curl -sSL -m 10 -o /dev/null -w "%{http_code}" http://10.50.0.102:8080/readycheck/) == "200" ] 
do
  echo "Waiting for Fedora to finish building..." >> /root/islandora.setup.txt 2>&1
  sleep 5
done
echo "Fedora has finished building!" >> /root/islandora.setup.txt 2>&1


# Download, install and configure Islandora modules & dependencies
echo -e "\nSetting up core Islandora module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/tuque.git /var/www/html/sites/all/libraries/tuque >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en libraries >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora.git /var/www/html/sites/all/modules/islandora >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_base_url "http://10.50.0.102:8080/fedora" >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up PHP Libs module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/php_lib.git /var/www/html/sites/all/modules/php_lib >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en php_lib >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Checksum & Checksum Checker modules (not enabled)..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_checksum.git /var/www/html/sites/all/modules/islandora_checksum >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_checksum_checker.git /var/www/html/sites/all/modules/islandora_checksum_checker >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora PREMIS module (not enabled)..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_premis.git /var/www/html/sites/all/modules/islandora_premis >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Pathauto module (not enabled)..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_pathauto.git /var/www/html/sites/all/modules/islandora_pathauto >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Populator module (not enabled)..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_populator.git /var/www/html/sites/all/modules/islandora_populator >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Simple Workflow module (not enabled)..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_simple_workflow.git /var/www/html/sites/all/modules/islandora_simple_workflow >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Basic Collection Solution Pack module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_solution_pack_collection.git /var/www/html/sites/all/modules/islandora_solution_pack_collection >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_basic_collection >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Usage Stats module..." >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y dl date
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y dl datepicker
git clone https://github.com/Islandora/islandora_usage_stats.git /var/www/html/sites/all/modules/islandora_usage_stats >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_usage_stats >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Batch module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_batch.git /var/www/html/sites/all/modules/islandora_batch >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_batch >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Importer module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_importer.git /var/www/html/sites/all/modules/islandora_importer >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_importer >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora XACML Editor module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_xacml_editor.git /var/www/html/sites/all/modules/islandora_xacml_editor >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_xacml_editor >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Objective Forms module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/objective_forms.git /var/www/html/sites/all/modules/objective_forms >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en objective_forms >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora XML Forms module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_xml_forms.git /var/www/html/sites/all/modules/islandora_xml_forms >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en xml_forms >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Badges module..." >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_badges.git /var/www/html/sites/all/modules/islandora_badges >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_badges >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora PDFjs viewer module..." >> /root/islandora.setup.txt 2>&1
mkdir /tmp/pdfjs >> /root/islandora.setup.txt 2>&1
wget -O /tmp/pdfjs/pdfjs.zip https://github.com/mozilla/pdf.js/releases/download/v1.9.426/pdfjs-1.9.426-dist.zip >> /root/islandora.setup.txt 2>&1
unzip /tmp/pdfjs/pdfjs.zip >> /root/islandora.setup.txt 2>&1
rm /tmp/pdfjs/pdfjs.zip >> /root/islandora.setup.txt 2>&1
mv /tmp/pdfjs /var/www/html/sites/all/libraries/ >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_pdfjs.git /var/www/html/sites/all/modules/islandora_pdfjs >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_pdfjs >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora Basic Image Solution Pack module..." >> /root/islandora.setup.txt 2>&1
yum -y install ImageMagick >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en imagemagick >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset image_toolkit imagemagick >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset imagemagick_convert /usr/bin/convert >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_solution_pack_image.git /var/www/html/sites/all/modules/islandora_solution_pack_image >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_basic_image >> /root/islandora.setup.txt 2>&1

echo -e "\nSetting up Islandora PDF Solution Pack module..." >> /root/islandora.setup.txt 2>&1
yum -y install ImageMagick poppler-utils ghostscript  >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en imagemagick >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset image_toolkit imagemagick >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset imagemagick_convert /usr/bin/convert >> /root/islandora.setup.txt 2>&1
git clone https://github.com/Islandora/islandora_solution_pack_pdf.git /var/www/html/sites/all/modules/islandora_solution_pack_pdf >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y en islandora_pdf >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_pdf_allow_text_upload 1 >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_pdf_create_fulltext 1 >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_pdf_create_pdfa 1 >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_pdf_path_to_gs /usr/bin/gs >> /root/islandora.setup.txt 2>&1
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y vset islandora_pdf_path_to_pdftotext /usr/bin/pdftotext >> /root/islandora.setup.txt 2>&1
php -r "print json_encode(array('default' => 'islandora_pdfjs'));"  | /root/.composer/vendor/bin/drush --root=/var/www/html --uri=default --user=1 vset --format=json islandora_pdf_viewers - >> /root/islandora.setup.txt 2>&1


# Run custom provisioning
wget $CUSTOM_SH_SCRIPT_URL -O /tmp/custom.sh
chmod +x /tmp/custom.sh
#sh /tmp/custom.sh >> /root/custom.setup.txt 2>&1

# Final refresh of system before exiting
/root/.composer/vendor/bin/drush --user=1 --root=/var/www/html --uri=default -y cc all
service httpd restart
