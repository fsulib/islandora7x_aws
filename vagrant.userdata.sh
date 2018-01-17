#!/bin/bash

# Export all relevant username/password CF params
export DATABASE_ROOT_USER=dbrootu
export DATABASE_ROOT_PASS=dbrootp
export DRUPAL_DATABASE_USER=drupaldbu
export DRUPAL_DATABASE_PASS=drupaldbp
export FEDORA_DATABASE_USER=fedoradbu
export FEDORA_DATABASE_PASS=fedoradbp
export FEDORA_FILTER_USER=fedorafilteru
export FEDORA_FILTER_PASS=fedorafilterp
export TOMCAT_MANAGER_USER=tomcatmanu
export TOMCAT_MANAGER_PASS=tomcatmanp

wget https://raw.githubusercontent.com/fsulib/islandora7x_aws/master/UserData/fedora.sh -O /root/fedora.sh
sh /root/fedora.sh
