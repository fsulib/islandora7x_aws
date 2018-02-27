echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseEndpoint: ${DATABASE_ENDPOINT}" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "DrupalDatabaseUser: ${DRUPAL_DATABASE_USER}" >> /root/build-params.txt
echo "DrupalDatabasePass: ${DRUPAL_DATABASE_PASS}" >> /root/build-params.txt
echo "FedoraDatabaseUser: ${FEDORA_DATABASE_USER}" >> /root/build-params.txt
echo "FedoraDatabasePass: ${FEDORA_DATABASE_PASS}" >> /root/build-params.txt
echo "FedoraAdminPass: ${FEDORA_ADMIN_PASS}" >> /root/build-params.txt
echo "TomcatManagerUser: ${TOMCAT_MANAGER_USER}" >> /root/build-params.txt
echo "TomcatManagerPass: ${TOMCAT_MANAGER_PASS}" >> /root/build-params.txt

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
yum -y remove java-1.7.0-openjdk >> /root/updates.txt
yum -y install mysql java-1.8.0 > /root/installs.txt
yum -y install tomcat7 >> /root/installs.txt
yum -y install git >> /root/installs.txt
yum -y install ant >> /root/installs.txt

# Configure MySQL
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE DATABASE fedoradb;"
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="CREATE USER '${FEDORA_DATABASE_USER}'@'10.50.0.102' IDENTIFIED BY '${FEDORA_DATABASE_PASS}';"
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="GRANT ALL PRIVILEGES ON fedoradb.* TO ${FEDORA_DATABASE_USER}@10.50.0.102;"
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="FLUSH PRIVILEGES;"
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="ALTER DATABASE fedoradb DEFAULT CHARACTER SET utf8;"
mysql --user="${DATABASE_ROOT_USER}" --password="${DATABASE_ROOT_PASS}" --host="${DATABASE_ENDPOINT}" --execute="ALTER DATABASE fedoradb DEFAULT COLLATE utf8_bin;"

# Setup variables needed by Fedora
export JAVA_HOME="/usr/lib/jvm/jre-1.8.0-openjdk.x86_64"
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
export PATH=$PATH:$JAVA_HOME/bin
echo "PATH=$PATH" >> /etc/environment
export FEDORA_HOME="/usr/local/fedora"
echo "FEDORA_HOME=$FEDORA_HOME" >> /etc/environment

# Download install.properties file and rewrite variables
cd /root
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/install.properties
perl -i -p -e 's/DBServer/$ENV{DATABASE_ENDPOINT}/g' install.properties
perl -i -p -e 's/fedoraDBuser/$ENV{FEDORA_DATABASE_USER}/g' install.properties
perl -i -p -e 's/fedoraDBpass/$ENV{FEDORA_DATABASE_PASS}/g' install.properties
perl -i -p -e 's/fedoraAdminPass/$ENV{FEDORA_ADMIN_PASS}/g' install.properties

# Install Fedora Commons
mkdir "$FEDORA_HOME"
wget -q -O "/root/fcrepo-installer-3.8.1.jar" "https://github.com/fcrepo3/fcrepo/releases/download/v3.8.1/fcrepo-installer-3.8.1.jar"
java -jar fcrepo-installer-3.8.1.jar install.properties >> /root/installs.txt 2>&1

# Deploy fcrepo
chown tomcat:tomcat /var/lib/tomcat7/webapps/fedora.war
chown -hR tomcat:tomcat "$FEDORA_HOME"
service tomcat7 restart >> /root/installs.txt 2>&1
sleep 45

# Setup XACML Policies
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-inactive-or-deleted-objects-or-datastreams-if-not-administrator.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-policy-management-if-not-administrator.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-unallowed-file-resolution.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-purge-datastream-if-active-or-inactive.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-purge-object-if-active-or-inactive.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/default/deny-reloadPolicies-if-not-localhost.xml
cd "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/
git clone https://github.com/Islandora/islandora-xacml-policies.git islandora
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/islandora/permit-apim-to-anonymous-user.xml
rm -f "$FEDORA_HOME"/data/fedora-xacml-policies/repository-policies/islandora/permit-upload-to-anonymous-user.xml
sed -i '31i <AttributeValue DataType="http://www.w3.org/2001/XMLSchema#string">10.50.0.101</AttributeValue>' default/deny-apim-if-not-localhost.xml

# Setup Drupal filter
wget -q -O "/root/fcrepo-drupalauthfilter-3.8.1.jar" https://github.com/Islandora/islandora_drupal_filter/releases/download/v7.1.3/fcrepo-drupalauthfilter-3.8.1.jar
cp "/root/fcrepo-drupalauthfilter-3.8.1.jar" /var/lib/tomcat7/webapps/fedora/WEB-INF/lib
chown tomcat:tomcat /var/lib/tomcat7/webapps/fedora/WEB-INF/lib/fcrepo-drupalauthfilter-3.8.1.jar
wget -q -O "/root/jaas.conf" https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/jaas.conf
cp /root/jaas.conf "$FEDORA_HOME"/server/config
wget -q -O "/root/filter-drupal.xml" https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/filter-drupal.xml
cd /root
perl -i -p -e 's/DBServer/$ENV{DATABASE_ENDPOINT}/g' filter-drupal.xml
perl -i -p -e 's/drupalDBuser/$ENV{DRUPAL_DATABASE_USER}/g' filter-drupal.xml
perl -i -p -e 's/drupalDBpass/$ENV{DRUPAL_DATABASE_PASS}/g' filter-drupal.xml
cp /root/filter-drupal.xml "$FEDORA_HOME"/server/config

# Download and Install Fedora GSearch
cd /root
wget https://github.com/discoverygarden/gsearch/releases/download/v2.8.1/fedoragsearch-2.8.1.zip
unzip fedoragsearch-2.8.1.zip
/bin/cp -v fedoragsearch-2.8.1/fedoragsearch.war /var/lib/tomcat7/webapps
chown tomcat:tomcat /var/lib/tomcat7/webapps/fedoragsearch.war
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/fedora-users.xml
perl -i -p -e 's/GSearchPass/$ENV{FEDORA_ADMIN_PASS}/g' fedora-users.xml
/bin/cp -f fedora-users.xml $FEDORA_HOME/server/config

service tomcat7 restart >> /root/installs.txt 2>&1

# Configure Fedora GSearch
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/fgsconfig-basic-for-islandora.properties
perl -i -p -e 's/fedoraAdminPass/$ENV{FEDORA_ADMIN_PASS}/g' fgsconfig-basic-for-islandora.properties
/bin/cp -f fgsconfig-basic-for-islandora.properties /var/lib/tomcat7/webapps/fedoragsearch/FgsConfig >> /root/debugGsearch.txt 2>&1
cd /var/lib/tomcat7/webapps/fedoragsearch/FgsConfig >> /root/debugGsearch.txt 2>&1
perl -i -p -e 's/fgsconfig-basic.properties/fgsconfig-basic-for-islandora.properties/g' fgsconfig-basic.xml >> /root/debugGsearch.txt 2>&1
ant -f fgsconfig-basic.xml >> /root/debugGsearch.txt 2>&1
rm -f /var/lib/tomcat7/webapps/fedoragsearch/WEB-INF/lib/log4j-over-slf4j-1.5.10.jar >> /root/debugGsearch.txt 2>&1
echo "Done with Gsearch configuration" >> /root/debugGsearch.txt 2>&1

service tomcat7 restart >> /root/debugGsearch.txt 2>&1
