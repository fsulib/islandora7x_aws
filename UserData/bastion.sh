echo "10.50.0.101 drupal drupal" >> /etc/hosts
echo "10.50.0.102 fedora fedora" >> /etc/hosts
echo "10.50.0.103 solr solr" >> /etc/hosts
yum -y update > /root/updates.txt

echo "alias drupal='ssh ec2-user@drupal'" >> /home/ec2-user/.bashrc
echo "alias solr='ssh ec2-user@solr'" >> /home/ec2-user/.bashrc
echo "alias fedora='ssh ec2-user@fedora'" >> /home/ec2-user/.bashrc
