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

# Install Solr and configure it to auto start on boot
cd /root
wget https://archive.apache.org/dist/lucene/solr/4.6.1/solr-4.6.1.tgz
wget https://raw.githubusercontent.com/fcrepo3/gsearch/master/FgsConfig/FgsConfigIndexTemplate/Solr/conf/schema-4.6.1-for-fgs-2.8.xml