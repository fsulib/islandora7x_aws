echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseEndpoint: ${DATABASE_ENDPOINT}" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "FedoraDatabaseUser: ${FEDORA_DATABASE_USER}" >> /root/build-params.txt
echo "FedoraDatabasePass: ${FEDORA_DATABASE_PASS}" >> /root/build-params.txt
echo "FedoraFilterUser: ${FEDORA_FILTER_USER}" >> /root/build-params.txt
echo "FedoraFilterPass: ${FEDORA_FILTER_PASS}" >> /root/build-params.txt
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
yum -y install mysql > /root/installs.txt
