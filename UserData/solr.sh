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
yum -y update > /root/updates.txt 2>&1
yum -y install tomcat7 >> /root/installs.txt 2>&1

# Setup variables needed by Solr
export PATH=$PATH:$JAVA_HOME/bin
export CATALINA_HOME=/var/lib/tomcat7
export CATALINA_BASE=/var/lib/tomcat7
export CLASSPATH=$JAVA_HOME/lib

# Download and Install Solr
cd /root
wget https://archive.apache.org/dist/lucene/solr/4.6.1/solr-4.6.1.tgz >> /root/solrinstall.txt 2>&1
wget https://raw.githubusercontent.com/fcrepo3/gsearch/master/FgsConfig/FgsConfigIndexTemplate/Solr/conf/schema-4.6.1-for-fgs-2.8.xml >> /root/solrinstall.txt 2>&1
wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/solr.xml
tar -xzvf solr-4.6.1.tgz >> /root/solrinstall.txt 2>&1
cp -v /root/solr-4.6.1/dist/solr-4.6.1.war /var/lib/tomcat7/webapps/solr.war >> /root/solrinstall.txt 2>&1
chown tomcat:tomcat /var/lib/tomcat7/webapps/solr.war >> /root/solrinstall.txt 2>&1

service tomcat7 restart >> /root/solrinstall.txt 2>&1
sleep 45

# Configure the local solr folder
mkdir -p /usr/local/solr >> /root/solrinstall.txt 2>&1
cp -r /root/solr-4.6.1/example/solr/. /usr/local/solr/ >> /root/solrinstall.txt 2>&1
cp -r /root/solr-4.6.1/example/lib/ext/. /var/lib/tomcat7/webapps/solr/WEB-INF/lib/ >> /root/solrinstall.txt 2>&1
cp /root/solr.xml /etc/tomcat7/Catalina/localhost/ >> /root/solrinstall.txt 2>&1
/bin/cp -f /root/schema-4.6.1-for-fgs-2.8.xml /usr/local/solr/collection1/conf/schema.xml >> /root/solrinstall.txt 2>&1
chown -R tomcat:tomcat /usr/local/solr >> /root/solrinstall.txt 2>&1
service tomcat7 restart >> /root/solrinstall.txt 2>&1
echo "Done with Solr configuration" >> /root/solrinstall.txt 2>&1