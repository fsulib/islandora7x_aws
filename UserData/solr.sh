yum -y update > /root/updates.txt

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