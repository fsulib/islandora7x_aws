echo "Build Parameters:" >> /root/build-params.txt
echo "DatabaseRootUser: ${DATABASE_ROOT_USER}" >> /root/build-params.txt
echo "DatabaseRootPass: ${DATABASE_ROOT_PASS}" >> /root/build-params.txt
echo "FedoraDatabaseUser: ${FEDORA_DATABASE_USER}" >> /root/build-params.txt
echo "FedoraDatabasePass: ${FEDORA_DATABASE_PASS}" >> /root/build-params.txt
echo "FedoraFilterUser: ${FEDORA_FILTER_USER}" >> /root/build-params.txt
echo "FedoraFilterPass: ${FEDORA_FILTER_PASS}" >> /root/build-params.txt
echo "TomcatManagerUser: ${TOMCAT_MANAGER_USER}" >> /root/build-params.txt
echo "TomcatManagerPass: ${TOMCAT_MANAGER_PASS}" >> /root/build-params.txt

yum -y update > /root/updates.txt
