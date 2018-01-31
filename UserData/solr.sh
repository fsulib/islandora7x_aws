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
yum -y install java-1.8.0 >> /root/updates.txt
yum -y remove java-1.7.0-openjdk >> /root/updates.txt

# Install Solr and configure it to auto start on boot
cd /root
wget http://mirror.cc.columbia.edu/pub/software/apache/lucene/solr/7.2.1/solr-7.2.1.tgz
tar xzf solr-7.2.1.tgz solr-7.2.1/bin/install_solr_service.sh --strip-components=2
./install_solr_service.sh solr-7.2.1.tgz >> /root/updates.txt
