echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseEndpoint: ${DATABASE_ENDPOINT}" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
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